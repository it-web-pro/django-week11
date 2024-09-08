# Database transactions in Django

[Doc](https://docs.djangoproject.com/en/5.1/topics/db/transactions/)

Django มี decorator `transaction.atomic` ให้ใช้สำหรับถ้าเราต้องการควบคุมการทำ database transaction ของ view

```python
from django.db import transaction


@transaction.atomic
def viewfunc(request):
    # This code executes inside a transaction.
    do_stuff()
```

และสามารถใช้งาน `transaction.atomic` ในรูปแบบของ context manager

```python
from django.db import transaction


def viewfunc(request):
    # This code executes in autocommit mode (Django's default).
    do_stuff()

    with transaction.atomic():
        # This code executes inside a transaction.
        do_more_stuff()
```

!! IMPORTANT !!

> ไม่ควร try catch exception ใน `transaction.atomic` เนื่องจากการออกจาก atomic block นั้น Django จะต้องดูว่าเป็นการออกแบบสำเร็จ (commit) หรือ เป็นการออกแบบไม่สำเร็จ (rollback) ถ้าเรามีการ catch exception (โดยเฉพาะ exception ที่เกี่ยวกับ database เช่น `DatabaseError` หรือ `IntegrityError`) โดยถ้าคุณพยายามที่จะ catch exception เหล่านี้ใน transaction Django จะ raise `TransactionManagementError`

วิธีที่ถูกต้องถ้าเราต้องการ catch exception คือ

```python
@transaction.atomic
def viewfunc(request):
    create_parent()

    try:
        with transaction.atomic():
            generate_relationships()
    except IntegrityError:
        handle_exception()

    add_children()
```

Django จัดการ transaction ดังนี้:

1. ทำการ opens transaction เมื่อมีการทำงานของ atomic block ตัวนอกสุด
2. สร้าง savepoint เมื่อมีการเข้าทำงานใน atomic block ตัวใน
3. ทำการ release หรือ roll back เมื่อออกจาก atomic ิblock ตัวใน
4. ทำการ commit หรือ roll back transaction เมื่ออกจาก atomic block ตัวนอกสุด

## Performing actions after commit

ถ้าเราต้องการทำ action อะไรสักอย่างหลังจากการจาก commit transaction เราสามารถใช้ `on_commit()` ได้

> on_commit(func, using=None, robust=False)

```python
from django.db import transaction


def send_welcome_email(): ...


transaction.on_commit(send_welcome_email)
```

ถ้าต้องการส่ง argument เข้า function callback สามารถทำได้โดยใช้ `functools.partial()`

```python
from functools import partial

for user in users:
    transaction.on_commit(partial(send_invite_email, user=user))
```

## Let's see some example

1. สร้าง project `week11_tutorial` และ app `account`
2. เรามาลองดูแบบไม่ใช้งาน transaction กันเพิ่ม code นี้ใน `account/models.py`

```python
class Account(models.Model):
    owner = models.CharField(max_length=100)
    account_no = models.CharField(max_length=20)
    balance = models.DecimalField(max_digits=10, decimal_places=2)

    def transfer_funds(self, to_account_no, amount):
        try:
            from_account = self
            if from_account.balance < amount:
                raise ValueError("Insufficient funds in the source account.")
            # Debit the amount from the source account
            from_account.balance = F('balance') - amount
            from_account.save()

            to_account = Account.objects.get(account_no=to_account_no)
            # Credit the amount to the destination account
            to_account.balance = F('balance') + amount
            to_account.save()
        except ObjectDoesNotExist:
            print("Account does not exist.")
```

3. เปิด Django shell และ ทำการ insert ข้อมูลในตาราง `Account`

```python
>>> a1 = Account.objects.create(owner="A", account_no="001", balance=10000)

>>> a2 = Account.objects.create(owner="B", account_no="002", balance=5000)
```

4. ลองทำการโอนเงินจาก A -> B จำนวน 1000

```python
>>> a1.transfer_funds(to_account_no="002", amount=1000)
```

5. ตรวจสอบข้อมูลใน database ว่าถูกต้องหรือไม่

6. ทีนี้เรามาลองทำให้เกิด error ระหว่างการโอนกัน โดยลองโอนเงินจาก B ไปยัง account ที่ไม่มีในระบบ

```python
>>> a2.transfer_funds(to_account_no="003", amount=5000)
'Account does not exist.'
```

7. ลองตรวจสอบข้อมูลใน database ว่าถูกต้องหรือไม่

8. จากนั้นเรามาลองแก้ไข code เพื่อใช้งาน transaction กันดูครับ (อย่าลืม restart Django shell)

```python
...

def transfer_funds(self, to_account_no, amount):
    try:
        with transaction.atomic():
            from_account = self
            if from_account.balance < amount:
                raise ValueError("Insufficient funds in the source account.")
            # Debit the amount from the source account
            from_account.balance = F('balance') - amount
            from_account.save()

            to_account = Account.objects.get(account_no=to_account_no)
            # Credit the amount to the destination account
            to_account.balance = F('balance') + amount
            to_account.save()

    except ObjectDoesNotExist:
        print("Account does not exist.")

```

9. ลองทำตามขั้นตอนที่ 6 อีกรอบ และตรวจสอบข้อมูลใน database
