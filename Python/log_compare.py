#!/usr/bin/env python3
"""
Loki vs ClickHouse log comparison script.

Compares total log counts between:
  - IONOS Managed Grafana/Loki
  - ClickHouse (fluentbit.kube_logs table)

For a configurable time window (default: last N minutes from now).

Usage:
  python3 log_comparison_loki_clickhouse.py
"""

import datetime as dt
import time
from zoneinfo import ZoneInfo
import requests

# ==========================
# CONFIG
# ==========================

# IONOS Managed Grafana endpoint (original method)
GRAFANA_BASE = "LOKI ENDPOINT"
GRAFANA_API_TOKEN = "TOKEN"

# IONOS Logging Service API (direct pipeline access) – not used yet
IONOS_LOGGING_BASE = "https://logging.de-txl.ionos.com"
IONOS_PIPELINE_ID = "41abdea6-b580-11f0-9244-46635f35935a"
IONOS_API_TOKEN = None

LOKI_QUERY_METHOD = "grafana"

# For long windows, break into chunks
LOKI_CHUNK_MINUTES = 15  # 15-minute chunks

# ClickHouse HTTP interface
CH_URL = "http://IP:PORT"
CH_USER = "default"
CH_PASSWORD = "PASS"
CH_DATABASE = "fluentbit"
CH_TABLE = "kube_logs"
CH_TIMESTAMP_COLUMN = "timestamp"

# Bulgarian timezone
BULGARIAN_TZ = ZoneInfo("Europe/Sofia")

# Time window mode:
# "from_hour" = from specific hour today (e.g., 16:00 Bulgarian)
# "last_minutes" = last N minutes from now
TIME_MODE = "last_minutes"

# For "from_hour" mode:
START_HOUR_BULGARIAN = 16

# For "last_minutes" mode:
LAST_MINUTES = 120  # last 120 minutes

# Loki selector
LOKI_PIPELINE_ID = "41abdea6-b580-11f0-9244-46635f35935a"
LOKI_FILTER_NAMESPACE = None


# ==========================
# TIME WINDOW HELPERS
# ==========================

def get_time_window() -> tuple[dt.datetime, dt.datetime, int]:
    """Return (start_utc, end_utc, window_seconds)."""
    now_utc = dt.datetime.now(dt.timezone.utc)

    if TIME_MODE == "last_minutes":
        start_utc = now_utc - dt.timedelta(minutes=LAST_MINUTES)
        end_utc = now_utc
    else:
        now_bg = now_utc.astimezone(BULGARIAN_TZ)
        start_bg = now_bg.replace(
            hour=START_HOUR_BULGARIAN,
            minute=0,
            second=0,
            microsecond=0,
        )
        if now_bg < start_bg:
            start_bg = start_bg - dt.timedelta(days=1)
        start_utc = start_bg.astimezone(dt.timezone.utc)
        end_utc = now_utc

    window_seconds = int((end_utc - start_utc).total_seconds())
    return start_utc, end_utc, window_seconds


def print_time_window(start_dt: dt.datetime, end_dt: dt.datetime, window_seconds: int) -> None:
    start_bg = start_dt.astimezone(BULGARIAN_TZ)
    end_bg = end_dt.astimezone(BULGARIAN_TZ)

    print("=" * 60)
    print("TIME WINDOW")
    print("=" * 60)
    if TIME_MODE == "last_minutes":
        print(f"MODE: Last {LAST_MINUTES} minutes")
    else:
        print(f"MODE: From {START_HOUR_BULGARIAN}:00 Bulgarian time")
    print(f"START: {start_bg:%Y-%m-%d %H:%M:%S %Z} (Bulgarian)")
    print(f"       {start_dt:%Y-%m-%dT%H:%M:%SZ} (UTC)")
    print(f"END:   {end_bg:%Y-%m-%d %H:%M:%S %Z} (Bulgarian)")
    print(f"       {end_dt:%Y-%m-%dT%H:%M:%SZ} (UTC)")
    print(f"DURATION: {window_seconds} seconds ({window_seconds/60:.1f} min / {window_seconds/3600:.2f} hours)")
    if LOKI_PIPELINE_ID:
        print(f"LOKI FILTER: pipeline_id={LOKI_PIPELINE_ID}")
    elif LOKI_FILTER_NAMESPACE:
        print(f"LOKI FILTER: namespace_name={LOKI_FILTER_NAMESPACE}")
    else:
        print("LOKI FILTER: none (all logs)")


# ==========================
# LOKI FUNCTIONS
# ==========================

def get_grafana_headers() -> dict:
    return {"Authorization": f"Bearer {GRAFANA_API_TOKEN}"}


def discover_loki_datasource() -> dict:
    url = f"{GRAFANA_BASE}/api/datasources"
    resp = requests.get(url, headers=get_grafana_headers(), timeout=60)

    print("\n" + "=" * 60)
    print("LOKI DATASOURCE DISCOVERY")
    print("=" * 60)
    print(f"GET {url}")
    print(f"HTTP {resp.status_code}")
    resp.raise_for_status()

    data = resp.json()
    loki_ds = next((ds for ds in data if ds.get("type") == "loki"), None)
    if not loki_ds:
        raise RuntimeError("No Loki datasource found in Grafana")

    ds_id = loki_ds.get("id")
    ds_uid = loki_ds.get("uid")
    ds_name = loki_ds.get("name")
    ds_url = (loki_ds.get("url") or "").rstrip("/")

    api_prefix = "/api/v1" if ds_url.endswith("/loki") else "/loki/api/v1"

    print(f"Found: id={ds_id}, uid={ds_uid}, name={ds_name}")
    print(f"URL: {ds_url}")
    print(f"API prefix: {api_prefix}")

    return {
        "id": ds_id,
        "uid": ds_uid,
        "name": ds_name,
        "url": ds_url,
        "api_prefix": api_prefix,
    }


def query_loki_total(ds_info: dict, start_dt: dt.datetime, end_dt: dt.datetime, window_seconds: int) -> int:
    chunk_seconds = LOKI_CHUNK_MINUTES * 60
    if LOKI_CHUNK_MINUTES > 0 and window_seconds > chunk_seconds:
        return query_loki_total_chunked(ds_info, start_dt, end_dt, chunk_seconds)
    return query_loki_single(ds_info, start_dt, end_dt, window_seconds)


def query_loki_total_chunked(ds_info: dict, start_dt: dt.datetime, end_dt: dt.datetime, chunk_seconds: int) -> int:
    print("\n" + "=" * 60)
    print("LOKI QUERY (CHUNKED)")
    print("=" * 60)
    print(f"Breaking into {chunk_seconds // 60} minute chunks...")

    total_count = 0
    chunk_start = start_dt
    chunk_num = 0

    while chunk_start < end_dt:
        chunk_end = min(chunk_start + dt.timedelta(seconds=chunk_seconds), end_dt)
        chunk_window = int((chunk_end - chunk_start).total_seconds())
        chunk_num += 1

        print(f"\nChunk {chunk_num}: {chunk_start.strftime('%H:%M:%S')} - {chunk_end.strftime('%H:%M:%S')} ({chunk_window}s)")

        try:
            chunk_count = query_loki_single(ds_info, chunk_start, chunk_end, chunk_window, quiet=True)
            total_count += chunk_count
            print(f"  -> {chunk_count:,} logs (running total: {total_count:,})")
        except Exception as e:
            print(f"  -> ERROR: {e}")

        chunk_start = chunk_end
        time.sleep(0.5)

    print("\n" + "=" * 40)
    print(f"TOTAL from all chunks: {total_count:,} logs")
    return total_count


def query_loki_single(
    ds_info: dict,
    start_dt: dt.datetime,
    end_dt: dt.datetime,
    window_seconds: int,
    quiet: bool = False,
) -> int:
    loki_base = f"{GRAFANA_BASE}/api/datasources/proxy/{ds_info['id']}"
    api_prefix = ds_info["api_prefix"]

    if LOKI_PIPELINE_ID:
        selector = f'{{pipeline_id="{LOKI_PIPELINE_ID}"}}'
    elif LOKI_FILTER_NAMESPACE:
        selector = f'{{namespace_name="{LOKI_FILTER_NAMESPACE}"}}'
    else:
        selector = '{}'

    logql = f'sum(count_over_time({selector}[{window_seconds}s]))'

    start_ns = int(start_dt.timestamp()) * 1_000_000_000
    end_ns = int(end_dt.timestamp()) * 1_000_000_000
    step_seconds = min(3600, window_seconds)

    url = f"{loki_base}{api_prefix}/query_range"
    params = {
        "query": logql,
        "start": str(start_ns),
        "end": str(end_ns),
        "step": str(step_seconds),
    }

    if not quiet:
        print("\n" + "=" * 60)
        print("LOKI QUERY")
        print("=" * 60)
        print(f"GET {url}")
        print(f"LogQL: {logql}")
        print(f"Time range: {start_dt.isoformat()} to {end_dt.isoformat()}")
        print(f"Start (ns): {start_ns}")
        print(f"End (ns):   {end_ns}")

    max_retries = 3
    resp = None
    for attempt in range(max_retries):
        try:
            resp = requests.get(url, headers=get_grafana_headers(), params=params, timeout=300)

            if not quiet:
                extra = f" (attempt {attempt + 1})" if attempt > 0 else ""
                print(f"HTTP {resp.status_code}{extra}")

            if resp.status_code == 502 and attempt < max_retries - 1:
                if not quiet:
                    print("Got 502, retrying in 5 seconds...")
                time.sleep(5)
                continue

            if resp.status_code != 200:
                if not quiet:
                    print(f"Error response: {resp.text[:500]}")
                resp.raise_for_status()

            break
        except requests.exceptions.Timeout:
            if attempt < max_retries - 1:
                if not quiet:
                    print("Timeout, retrying...")
                continue
            raise

    data = resp.json()

    if not quiet:
        print(f"Response status: {data.get('status')}")
        print(f"Result type: {data.get('data', {}).get('resultType')}")

    result = data.get("data", {}).get("result", [])
    if not result:
        if not quiet:
            print("No results returned")
            print(f"Raw response: {data}")
        return 0

    if not quiet:
        print(f"Number of series: {len(result)}")

    values = result[0].get("values") or result[0].get("value")
    if not values:
        if not quiet:
            print("Empty values in result")
        return 0

    if isinstance(values, list) and isinstance(values[0], list):
        if not quiet:
            print(f"Raw values count: {len(values)}")
            first_ts = dt.datetime.fromtimestamp(float(values[0][0]), tz=dt.timezone.utc)
            last_ts = dt.datetime.fromtimestamp(float(values[-1][0]), tz=dt.timezone.utc)
            print(f"First sample: {first_ts.isoformat()} = {values[0][1]}")
            print(f"Last  sample: {last_ts.isoformat()} = {values[-1][1]}")
        count_str = values[-1][1]
    elif isinstance(values, list) and len(values) == 2 and isinstance(values[1], str):
        if not quiet:
            ts = dt.datetime.fromtimestamp(float(values[0]), tz=dt.timezone.utc)
            print(f"Single value at: {ts.isoformat()} = {values[1]}")
        count_str = values[1]
    else:
        if not quiet:
            print(f"Unexpected values format: {type(values)} = {values}")
        count_str = str(values[-1]) if isinstance(values, list) else str(values)

    try:
        count = int(float(count_str))
        if not quiet:
            print(f"Result: {count:,} logs")
        return count
    except (ValueError, TypeError) as e:
        if not quiet:
            print(f"Failed to parse count from: {count_str} ({e})")
        return 0


# ==========================
# CLICKHOUSE FUNCTIONS
# ==========================

def query_clickhouse(sql: str) -> str:
    resp = requests.post(
        CH_URL,
        params={"query": sql},
        auth=(CH_USER, CH_PASSWORD),
        timeout=120,
    )
    if resp.status_code != 200:
        print(f"ClickHouse error: {resp.text[:500]}")
        resp.raise_for_status()
    return resp.text.strip()


def test_clickhouse_connection() -> bool:
    print("\n" + "=" * 60)
    print("CLICKHOUSE CONNECTION TEST")
    print("=" * 60)
    print(f"URL: {CH_URL}")
    print(f"User: {CH_USER}")
    print(f"Database: {CH_DATABASE}")
    print(f"Table: {CH_TABLE}")

    try:
        result = query_clickhouse("SELECT 1")
        print(f"Connection: OK (SELECT 1 = {result})")

        print(f"\nTable structure ({CH_DATABASE}.{CH_TABLE}):")
        columns = query_clickhouse(f"DESCRIBE {CH_DATABASE}.{CH_TABLE}")
        for line in columns.splitlines()[:10]:
            print(f"  {line}")

        count = query_clickhouse(f"SELECT count() FROM {CH_DATABASE}.{CH_TABLE}")
        print(f"\nTotal rows in table: {int(count):,}")
        return True
    except requests.exceptions.ConnectionError as e:
        print(f"Connection failed: {e}")
        return False
    except Exception as e:
        print(f"Error: {e}")
        return False


def query_clickhouse_counts(start_dt: dt.datetime, end_dt: dt.datetime) -> tuple[int, int, int]:
    """
    Return (total_rows, non_empty_rows, empty_rows) for the window.
    non_empty_rows = length(log) > 0
    """
    start_str = start_dt.strftime("%Y-%m-%d %H:%M:%S")
    end_str = end_dt.strftime("%Y-%m-%d %H:%M:%S")

    sql = f"""
    SELECT
        count() AS total_rows,
        countIf(length(log) > 0) AS non_empty_rows,
        countIf(length(log) = 0) AS empty_rows
    FROM {CH_DATABASE}.{CH_TABLE}
    WHERE {CH_TIMESTAMP_COLUMN} >= toDateTime('{start_str}')
      AND {CH_TIMESTAMP_COLUMN} <  toDateTime('{end_str}')
    """

    print("\n" + "=" * 60)
    print("CLICKHOUSE QUERY")
    print("=" * 60)
    print(f"SQL: {' '.join(sql.split())}")

    result = query_clickhouse(sql)
    first_line = result.splitlines()[0]
    parts = [p.strip() for p in first_line.split("\t")]
    if len(parts) != 3:
        raise RuntimeError(f"Unexpected ClickHouse response line: {first_line!r}")

    total_rows = int(parts[0])
    non_empty_rows = int(parts[1])
    empty_rows = int(parts[2])

    print(f"Total rows:      {total_rows:,}")
    print(f"Non-empty rows:  {non_empty_rows:,}")
    print(f"Empty rows:      {empty_rows:,}")

    debug_sql = f"""
    SELECT
        min({CH_TIMESTAMP_COLUMN}) AS min_ts,
        max({CH_TIMESTAMP_COLUMN}) AS max_ts
    FROM {CH_DATABASE}.{CH_TABLE}
    WHERE {CH_TIMESTAMP_COLUMN} >= toDateTime('{start_str}')
      AND {CH_TIMESTAMP_COLUMN} <  toDateTime('{end_str}')
    """
    debug_result = query_clickhouse(debug_sql)
    print(f"Actual timestamp range in data: {debug_result}")

    return total_rows, non_empty_rows, empty_rows


# ==========================
# COMPARISON & REPORTING
# ==========================

def print_comparison(
    loki_total: int,
    ch_total: int,
    ch_non_empty: int | None = None,
    ch_empty: int | None = None,
) -> None:
    print("\n" + "=" * 60)
    print("COMPARISON SUMMARY")
    print("=" * 60)

    print(f"{'Source':<25} {'Count':>15}")
    print("-" * 45)
    print(f"{'Loki (pipeline)':<25} {loki_total:>15,}")
    print(f"{'ClickHouse (ALL)':<25} {ch_total:>15,}")

    if ch_non_empty is not None and ch_empty is not None:
        print(f"{'ClickHouse (non-empty)':<25} {ch_non_empty:>15,}")
        print(f"{'ClickHouse (empty)':<25} {ch_empty:>15,}")
        print("-" * 45)
        diff_vs_non_empty = loki_total - ch_non_empty
        print(f"{'Diff vs non-empty':<25} {diff_vs_non_empty:>15,}")

        if ch_non_empty > 0:
            loki_pct = (loki_total / ch_non_empty) * 100
            print(f"{'Loki / CH(non-empty)':<25} {loki_pct:>14.2f}%")
        if loki_total > 0:
            ch_pct = (ch_non_empty / loki_total) * 100
            print(f"{'CH(non-empty) / Loki':<25} {ch_pct:>14.2f}%")
    else:
        print("-" * 45)
        diff = loki_total - ch_total
        print(f"{'Difference':<25} {diff:>15,}")
        if ch_total > 0:
            loki_pct = (loki_total / ch_total) * 100
            print(f"{'Loki/ClickHouse':<25} {loki_pct:>14.2f}%")
        if loki_total > 0:
            ch_pct = (ch_total / loki_total) * 100
            print(f"{'ClickHouse/Loki':<25} {ch_pct:>14.2f}%")

    print()

    # Simple assessment
    base = ch_non_empty if ch_non_empty is not None and ch_non_empty > 0 else ch_total
    diff = loki_total - (ch_non_empty if ch_non_empty is not None else ch_total)

    if base == 0 and loki_total == 0:
        print("⚠️  Both sources returned 0 logs - check time window and filters")
    elif base == 0:
        print("⚠️  ClickHouse returned 0 logs - check table/column names")
    elif loki_total == 0:
        print("⚠️  Loki returned 0 logs - check LogQL selector / pipeline_id")
    else:
        rel = abs(diff) / max(base, loki_total)
        if rel < 0.01:
            print("✅ Counts match within 1% (using non-empty rows) – good consistency.")
        elif rel < 0.05:
            print("⚠️  Counts differ by 1-5% (using non-empty rows) – minor discrepancy.")
        else:
            print("❌ Significant difference (using non-empty rows) – investigate pipelines / filters.")


# ==========================
# MAIN
# ==========================

def main():
    start_dt, end_dt, window_seconds = get_time_window()
    print_time_window(start_dt, end_dt, window_seconds)

    ch_ok = test_clickhouse_connection()

    try:
        ds_info = discover_loki_datasource()
        loki_ok = True
    except Exception as e:
        print(f"Failed to discover Loki datasource: {e}")
        loki_ok = False
        ds_info = None

    loki_total = 0
    ch_total = 0
    ch_non_empty = 0
    ch_empty = 0

    if loki_ok:
        loki_total = query_loki_total(ds_info, start_dt, end_dt, window_seconds)

    if ch_ok:
        ch_total, ch_non_empty, ch_empty = query_clickhouse_counts(start_dt, end_dt)

    print_comparison(loki_total, ch_total, ch_non_empty, ch_empty)


if __name__ == "__main__":
    main()
