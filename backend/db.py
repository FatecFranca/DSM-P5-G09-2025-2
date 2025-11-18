# backend/db.py
import os
from sqlalchemy import create_engine
from dotenv import load_dotenv

load_dotenv()

USER = os.getenv("DB_USER")
PASS = os.getenv("DB_PASS")
HOST = os.getenv("DB_HOST")
DB = os.getenv("DB_NAME")

CONN_STR = f"mysql+pymysql://{USER}:{PASS}@{HOST}/{DB}"
engine = create_engine(CONN_STR, pool_recycle=3600)
