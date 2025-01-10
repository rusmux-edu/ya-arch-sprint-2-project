import typing as tp

from pydantic import BaseModel, BeforeValidator, Field

# Represents an ObjectId field in the database.
# It will be represented as a `str` on the model so that it can be serialized to JSON.
PyObjectId = tp.Annotated[str, BeforeValidator(str)]


class UserModel(BaseModel):
    id: PyObjectId | None = Field(default=None, alias="_id")
    age: int
    name: str


class UserCollection(BaseModel):
    users: list[UserModel]
