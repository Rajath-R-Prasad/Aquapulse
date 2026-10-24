"""Authentication request bodies."""
from pydantic import BaseModel, Field, field_validator


class EngineerSignupBody(BaseModel):
    email: str = Field(min_length=3, max_length=320)
    password: str = Field(min_length=8, max_length=72)
    full_name: str = Field(min_length=1, max_length=120)
    phone: str | None = Field(default=None, max_length=32)

    @field_validator("email")
    @classmethod
    def normalize_email(cls, value: str) -> str:
        email = value.strip().lower()
        if email.count("@") != 1 or "." not in email.rsplit("@", 1)[1]:
            raise ValueError("Enter a valid email address")
        return email

    @field_validator("full_name")
    @classmethod
    def normalize_full_name(cls, value: str) -> str:
        name = value.strip()
        if not name:
            raise ValueError("Enter your full name")
        return name

    @field_validator("phone")
    @classmethod
    def normalize_phone(cls, value: str | None) -> str | None:
        if value is None:
            return None
        phone = value.strip()
        return phone or None


class OperatorSignupBody(BaseModel):
    email: str = Field(min_length=3, max_length=320)
    password: str = Field(min_length=8, max_length=72)
    full_name: str = Field(min_length=1, max_length=120)
    setup_code: str = Field(min_length=8, max_length=128)

    @field_validator("email")
    @classmethod
    def normalize_email(cls, value: str) -> str:
        email = value.strip().lower()
        if email.count("@") != 1 or "." not in email.rsplit("@", 1)[1]:
            raise ValueError("Enter a valid email address")
        return email

    @field_validator("full_name")
    @classmethod
    def normalize_full_name(cls, value: str) -> str:
        name = value.strip()
        if not name:
            raise ValueError("Enter your full name")
        return name

    @field_validator("setup_code")
    @classmethod
    def normalize_setup_code(cls, value: str) -> str:
        return value.strip()
