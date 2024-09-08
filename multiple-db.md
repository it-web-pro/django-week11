# Multiple databases

[Doc](https://docs.djangoproject.com/en/5.1/topics/db/multi-db/)

บางครั้งเราจำเป็นจะต้องใช้งาน database มากกว่า 1 database ใน website ของเรา

กรณีที่มักจะใช้กันยกตัวอย่างเช่น ระบบ website ของเรามี database ตัวหลัก และ database replica โดยถ้าการทำงานปกติเราจะ read-write ใน database ตัวหลัก แต่ถ้าเป็นการออกรายงานเราจะ read ที่ตัว replica 

## Defining your databases

ขั้นตอนแรกเราจะต้องไปทำการตั้งค่า connection database ที่เราจะใช้งานก่อนใน `settings.py`

```python
DATABASES = {
    "default": {
        "NAME": "app_data",
        "ENGINE": "django.db.backends.postgresql",
        "USER": "postgres_user",
        "PASSWORD": "s3krit",
    },
    "users": {
        "NAME": "user_data",
        "ENGINE": "django.db.backends.mysql",
        "USER": "mysql_user",
        "PASSWORD": "priv4te",
    },
}
```

## Synchronizing your databases

เราสามารถ migrate database โดยระบุ database ได้โดยการกำหนด option `--database` ยกตัวอย่างเช่น

```sh
$ ./manage.py migrate
$ ./manage.py migrate --database=users
```

โดยถ้าไม่กำหนด `--database` Django จะ migrate ไปที่ database "default" เสมอ


## Automatic database routing

โดยปกติถ้าเราไม่กำหนดอะไรเลย Django จะ connect และ query ข้อมูลจาก database "default" เสมอ แต่ถ้าเราต้องการกำหนดการ routing ว่าจะใช้ database ตัวไหนเมื่อไหร่ เราจะต้องใช้งาน class `Router` ซึ่งจะมี 4 methods ดังนี้

- `db_for_read(model, **hints)` - ระบุว่าให้ทำการ read จาก database ไหนสำหรับ model ที่กำหนด
- `db_for_write(model, **hints)` - ระบุว่าให้ทำการ write ลง database ไหนสำหรับ model ที่กำหนด
- `allow_relation(obj1, obj2, **hints)` - return True ถ้าความสัมพันธ์ระหว่าง obj1 และ obj2 นั้นควรเกิดขึ้นหรือไม่
- `allow_migrate(db, app_label, model_name=None, **hints)` - return True ถ้าสามารถรัน migration สำหรับ database ที่ระบุ และ model ที่ระบุหรือไม่

## An example

```python
# settings.py
DATABASES = {
    "default": {},
    "auth_db": {
        "NAME": "auth_db_name",
        "ENGINE": "django.db.backends.mysql",
        "USER": "mysql_user",
        "PASSWORD": "swordfish",
    },
    "primary": {
        "NAME": "primary_name",
        "ENGINE": "django.db.backends.mysql",
        "USER": "mysql_user",
        "PASSWORD": "spam",
    },
    "replica1": {
        "NAME": "replica1_name",
        "ENGINE": "django.db.backends.mysql",
        "USER": "mysql_user",
        "PASSWORD": "eggs",
    },
    "replica2": {
        "NAME": "replica2_name",
        "ENGINE": "django.db.backends.mysql",
        "USER": "mysql_user",
        "PASSWORD": "bacon",
    },
}
```

ทีนี้เราจะต้องไปกำหนด `Router` class สำหรับ app `auth` และ `contenttypes` ให้ทำการส่ง query ไปที่ "auth_db"

```python
class AuthRouter:
    """
    A router to control all database operations on models in the
    auth and contenttypes applications.
    """

    route_app_labels = {"auth", "contenttypes"}

    def db_for_read(self, model, **hints):
        """
        Attempts to read auth and contenttypes models go to auth_db.
        """
        if model._meta.app_label in self.route_app_labels:
            return "auth_db"
        return None

    def db_for_write(self, model, **hints):
        """
        Attempts to write auth and contenttypes models go to auth_db.
        """
        if model._meta.app_label in self.route_app_labels:
            return "auth_db"
        return None

    def allow_relation(self, obj1, obj2, **hints):
        """
        Allow relations if a model in the auth or contenttypes apps is
        involved.
        """
        if (
            obj1._meta.app_label in self.route_app_labels
            or obj2._meta.app_label in self.route_app_labels
        ):
            return True
        return None

    def allow_migrate(self, db, app_label, model_name=None, **hints):
        """
        Make sure the auth and contenttypes apps only appear in the
        'auth_db' database.
        """
        if app_label in self.route_app_labels:
            return db == "auth_db"
        return None
```

และกำหนดการ route ของ database "primary" และ "replica1" และ "replica2"

```python
import random


class PrimaryReplicaRouter:
    def db_for_read(self, model, **hints):
        """
        Reads go to a randomly-chosen replica.
        """
        return random.choice(["replica1", "replica2"])

    def db_for_write(self, model, **hints):
        """
        Writes always go to primary.
        """
        return "primary"

    def allow_relation(self, obj1, obj2, **hints):
        """
        Relations between objects are allowed if both objects are
        in the primary/replica pool.
        """
        db_set = {"primary", "replica1", "replica2"}
        if obj1._state.db in db_set and obj2._state.db in db_set:
            return True
        return None

    def allow_migrate(self, db, app_label, model_name=None, **hints):
        """
        All non-auth models end up in this pool.
        """
        return True
```

ขั้นสุดท้ายคือการไปกำหนด setting DATABASE_ROUTERS ใน `settings.py`

```python
DATABASE_ROUTERS = ["path.to.AuthRouter", "path.to.PrimaryReplicaRouter"]
```

## Manually selecting a database

เราสามารถเลือกว่าจะ connect ไปที่ database ตัวไหนได้สำหรับแต่ละ query โดยใช้ `using()`

```python
>>> # This will run on the 'default' database.
>>> Author.objects.all()

>>> # So will this.
>>> Author.objects.using("default")

>>> # This will run on the 'other' database.
>>> Author.objects.using("other")
```

### Selecting a database for save()

```python
>>> p = Person(name="Fred")
>>> p.save(using="other")
```

### Selecting a database to delete from

สามารถทำได้ 2 แบบ

```python
u = User.objects.using("other").get(username="fred")
u.delete()
```

```python
u.delete(using="other")
```

