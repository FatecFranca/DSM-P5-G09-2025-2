# backend/db.py
import os
from pathlib import Path

from dotenv import load_dotenv
from sqlalchemy import (
    JSON,
    Column,
    DateTime,
    Float,
    Integer,
    String,
    Text,
    create_engine,
    func,
)
from sqlalchemy.orm import declarative_base, sessionmaker

BASE_DIR = Path(__file__).resolve().parent
ENV_PATH = BASE_DIR / ".env"

# Permite que o .env fique dentro da pasta backend sem expor dados sensíveis
load_dotenv(ENV_PATH)

USER = os.getenv("DB_USER")
PASS = os.getenv("DB_PASS")
HOST = os.getenv("DB_HOST")
DB_NAME = os.getenv("DB_NAME")

if not all([USER, PASS, HOST, DB_NAME]):
    raise RuntimeError(
        "Credenciais do banco não encontradas. Verifique o arquivo backend/.env"
    )

CONN_STR = f"mysql+pymysql://{USER}:{PASS}@{HOST}/{DB_NAME}"
engine = create_engine(CONN_STR, pool_recycle=3600, pool_pre_ping=True)

SessionLocal = sessionmaker(bind=engine, autocommit=False, autoflush=False)
Base = declarative_base()


class AnalysisRecord(Base):
    """
    ORM responsável por mapear as análises de prenhez salvas no banco.
    """

    __tablename__ = "cow_analyses"

    id = Column(Integer, primary_key=True, index=True)
    cow_id = Column(String(128), nullable=False)
    prediction = Column(Integer, nullable=False)
    prediction_label = Column(String(8), nullable=False)
    probability = Column(Float, nullable=False)
    payload = Column(JSON, nullable=False)
    status = Column(String(32), nullable=False, default="completed")
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(
        DateTime(timezone=True),
        nullable=True,
        onupdate=func.now(),
    )


def init_db() -> None:
    """
    Cria as tabelas no banco (idempotente) para garantir que o CRUD funcione.
    """

    Base.metadata.create_all(bind=engine)


def get_session():
    """
    Helper para obter uma sessão nova do SQLAlchemy.
    """

    return SessionLocal()
