import hashlib
import json
import sys
from datetime import datetime
from pathlib import Path
import psycopg

BASE_DIR = Path(__file__).resolve().parent.parent.parent
if str(BASE_DIR) not in sys.path:
    sys.path.insert(0, str(BASE_DIR))

import config

def get_connection():
    return psycopg.connect(
        host=config.DB_HOST,
        port=config.DB_PORT,
        dbname=config.DB_NAME,
        user=config.DB_USER,
        password=config.DB_PASSWORD,
    )

table_comments = {
    'gold': 'Gold - The Gold layer contains denormalized, business-ready analytics and ROI metrics calculated from Silver data, optimized for direct querying by the AI Agent (Junimo Guide).',
    'silver' : 'Silver - The Silver layer contains clean, deduplicated, and unified data merged from Bronze sources using defined preference logic, enriched with lineage metadata (_dbt_updated_at, _primary_source, _is_merged).',
    'bronze' : 'Bronze - The Bronze layer contains raw, immutable JSONB payloads with system ingestion metadata (_source_file, _ingested_at, _file_hash). ',
    'bronze.crops_stardew_data' : 'Bronze - Listing of the crops in game extracted from the game files using stardew_data. The unifying of both crop sources will occur in the Silver layer. Addition of system ingestion metadata (_source_file, _ingested_at, _file_hash).',
    'bronze.crops_stardew_valley_data' : 'Bronze - Listing of the crops in game extracted from database on the github repository stardew_valley_data. The unifying of both crop sources will occur in the Silver layer. Addition of system ingestion metadata (_source_file, _ingested_at, _file_hash). '
}

def calculate_md5(file_path: Path) -> str:
    """Generate MD5 Hash"""
    hash_md5 = hashlib.md5()
    with open(file_path, "rb") as f:
        for chunk in iter(lambda: f.read(4096), b""):
            hash_md5.update(chunk)
    return hash_md5.hexdigest()


def setup_database_environment():
    con = get_connection()
    cur = con.cursor()

    cur.execute("CREATE SCHEMA IF NOT EXISTS bronze;")
    cur.execute("CREATE SCHEMA IF NOT EXISTS silver;")
    cur.execute("CREATE SCHEMA IF NOT EXISTS gold;")

    # general commentary
    db_comment = (
        "Central database for the Junimo Guide project. "
        "Stores Stardew Valley game data organized under the Medallion Architecture (Bronze, Silver, Gold). "
        "Serves as the data store for analytics, game mechanics optimization, and AI Agent query workflows."
    )

    cur.execute(f"COMMENT ON DATABASE junimo_db IS '{db_comment}';")

    # comment on bronze
    cur.execute(f"COMMENT ON SCHEMA bronze IS '{table_comments['bronze']}'")

    # comment on silver
    cur.execute(f"COMMENT ON SCHEMA silver IS '{table_comments['silver']}'")

    # comment on gold
    cur.execute(f"COMMENT ON SCHEMA gold IS '{table_comments['gold']}'")

    con.commit()

    cur.close()
    con.close()

def ingest_raw_source_to_bronze(field_name: str, raw_file_name: str, raw_source_name: str):
    raw_root = Path("data/raw")

    file_path = Path(f"{raw_root}/{raw_source_name}/{raw_file_name}")

    if not file_path.exists():
        print(f"File not found: {file_path}. Skipping...")
        return

    con = get_connection()
    cur = con.cursor()

    table_name = f"bronze.{field_name}_{raw_source_name}".replace("-", "_")

    cur.execute(f"""
        CREATE TABLE IF NOT EXISTS {table_name} (
            id SERIAL PRIMARY KEY,
            payload JSONB NOT NULL,
            _source_file TEXT NOT NULL,
            _ingested_at TIMESTAMP NOT NULL,
            _file_hash VARCHAR(32) UNIQUE
        );
    """)

    with open(file_path, "r", encoding="utf-8") as f:
                data = json.load(f)

    record = data if isinstance(data, list) else [data]
    source_file = str(file_path.relative_to(raw_root)).replace("\\", "/")
    file_hash = str(calculate_md5(file_path))
    ingested_at = datetime.now()

    cur.execute(
                f"""
                INSERT INTO {table_name} (payload, _source_file, _ingested_at, _file_hash)
                VALUES (%s, %s, %s, %s)
                ON CONFLICT (_file_hash) DO NOTHING;;
                """,
                (
                json.dumps(record),
                source_file,
                ingested_at,
                file_hash,
                    ),
                )

    ## Comment table
    if table_name in table_comments:
         cur.execute(f"COMMENT ON TABLE {table_name} IS '{table_comments[table_name]}'")
         print(f"Table {table_name} commented.")
    else:
        print(f"Couldnt find comment for table name: {table_name}")

    print(
        f"Ingestion completed: {file_path} Inserted in '{table_name}'."
    )

    con.commit()
    
    cur.close()
    con.close()

setup_database_environment()
ingest_raw_source_to_bronze("crops", "crops.json", "stardew-data")
ingest_raw_source_to_bronze("crops", "crops.json", "stardew-valley-data")


