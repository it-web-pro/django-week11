# WEEK 11 Exercise

## Part 1: Database Transaction

1.1 ให้ทำการเพิ่ม field ใน form `EmployeeForm` สำหรับข้อมูล `EmployeeAddress` (ดังใน code ด้านล่าง) จากนั้นแก้ไข view สร้าง employee ให้บันทึกข้อมูลลงทั้งในตาราง `employee_employee` และ `employee_employeeaddress` (0.5 คะแนน)

```python
class EmployeeForm(forms.ModelForm):
    location = forms.CharField(widget=forms.TextInput(attrs={"cols": 30, "rows": 3}))
    district = forms.CharField(max_length=100)
    province = forms.CharField(max_length=100)
    postal_code = forms.CharField(max_length=15)

    class Meta:
        model = Employee
        fields = [
            "first_name", 
            "last_name", 
            "gender", 
            "birth_date", 
            "hire_date", 
            "salary", 
            "position",
            "location",
            "district",
            "province",
            "postal_code"
        ]
        widgets = {
            'birth_date': forms.widgets.DateInput(attrs={'type': 'date'}),
            'hire_date': forms.widgets.DateInput(attrs={'type': 'date'})
        }
```

1.2 แสดงข้อมูลในหน้า list employees โดยเพิ่ม 2 columns ได้แก่ "location" (`EmployeeAddress.location`) และ "province" (`EmployeeAddress.province`) (0.25 คะแนน)

![img1-2](images/img1-2.png)

1.3 เนื่องจากมีการ insert ข้อมูลลงใน 2 ตารางต่อเนื่องกัน ให้ใช้งาน database transaction ใน view สร้าง employee (0.25 คะแนน)

**Hint:** ใช้เป็น block `with transaction.atomic()` หรือ decorator `@transaction.atomic`

## Part 2: Multiple Databases

ใน Part 2 เราจะมาลองใช้งาน multiple databases 

ก่อนเริ่มทำแบบฝึกหัดให้ทำตามขั้นตอนดังนี้

    1. สร้าง app ใหม่ชื่อ `company` ด้วยคำสั่ง `python manage.py startapp company`
    2. เพิ่ม app "company" ใน `settings.py`
    3. ลบ file migration ทั้งหมดใน folder `employee/migrations` เราจะทำการ makemigration ใหม่ทั้งหมด
    4. ทำการย้าย models `Department` และ `Position` ไปไว้ใน `company/models.py` โดยเราจะแยก database เป็น 2 ตัวได้แก่
        - `employee_db` สำหรับ model `Employee`, `EmployeeAddress` และ `Project`
        - `company_db` สำหรับ model `Department` และ `Position`

```python
# employee/models.py
from django.db import models

class Employee(models.Model):
    class Gender(models.TextChoices):
        M = "M", "Male"
        F = "F", "Female"
        LGBT = "LGBT", "LGBT"
        
    first_name = models.CharField(max_length=155)
    last_name = models.CharField(max_length=155)
    gender = models.CharField(max_length=10, choices=Gender.choices)
    birth_date = models.DateField()
    hire_date = models.DateField()
    salary = models.DecimalField(default=0, max_digits=10, decimal_places=2)
    position_id = models.IntegerField(null=True) # Change from ForeignKey to IntegerField
    
    def get_full_name(self):
        return f"{self.first_name} {self.last_name}"
    
    def __str__(self) -> str:
        return self.get_full_name()
    
class EmployeeAddress(models.Model):
    employee = models.OneToOneField("employee.Employee", on_delete=models.PROTECT)
    location = models.TextField(null=True, blank=True)
    district = models.CharField(max_length=100)
    province = models.CharField(max_length=100)
    postal_code = models.CharField(max_length=15)


class Project(models.Model):
    name = models.CharField(max_length=255, unique=True)
    description = models.TextField(null=True, blank=True)
    manager = models.OneToOneField(
        "employee.Employee", 
        on_delete=models.SET_NULL, 
        null=True, 
        blank=True,
        related_name="project_mamager"
    )
    due_date = models.DateField()
    start_date = models.DateField()
    staff = models.ManyToManyField("employee.Employee")
    
    def __str__(self):
        return str(self.name)
    
```

```python
# company/models.py
from django.db import models

# Create your models here.
class Department(models.Model):
    name = models.CharField(max_length=155)
    manager_id = models.IntegerField(null=True) # Change from ForeignKey to IntegerField

    class Meta:
        unique_together = ["id", "manager_id"] # Add unique contraint เพราะต้องการให้ employee 1 คนเป็น manager ได้ department เดียวเท่านั้น
    
    
class Position(models.Model):
    name = models.CharField(max_length=155)
    description = models.TextField(null=True, blank=True)
    department = models.ForeignKey(
        "company.Department",
        on_delete=models.SET_NULL, 
        null=True, 
        blank=True
    )
    
    def __str__(self):
        return str(self.name)
```

    5. แก้ไข setting DATABASES ใน `settings.y`

```python
DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.postgresql",
        "NAME": "employee_db", # อย่าลืมสร้าง db - employee_db ใน Postgres นะครับ
        "USER":  "postgres",
        "PASSWORD": "password",
        "HOST": "127.0.0.1",
        "PORT": "5432",
    },
    "db2": {
        "ENGINE": "django.db.backends.postgresql",
        "NAME": "company_db", # อย่าลืมสร้าง db - company_db ใน Postgres นะครับ
        "USER":  "postgres",
        "PASSWORD": "password",
        "HOST": "127.0.0.1",
        "PORT": "5432",
    }
}
```

2.1 ให้สร้างไฟล์ `company/routers.py` ขึ้นมาและ implement class `CompanyRouter` (0.25 คะแนน)

```python
# company/routers.py
class CompanyRouter:
    def db_for_read(self, model, **hints):
        return
    def db_for_write(self, model, **hints):
        return
    def allow_relation(self, obj1, obj2, **hints):
        return
    def allow_migrate(self, db, app_label, model_name=None, **hints):
        return
```

2.2 แก้ไข `settings.py` โดยเพิ่ม settings DATABASE_ROUTERS ให้ถูกต้อง (0.25 คะแนน)

จากนั้นทำตามขั้นตอนต่อไปนี้

    1. run command `python manage.py makemigrations`
    2. run command `python manage.py migrate` (สังเกตว่าตาราง company_department และ ตาราง company_position จะไม่ถูก migrate ลง `employee_db`)
    3. run comment `python manage.py migrate --database=db2 company` (สังเกตว่าตาราง company_department และ ตาราง company_position จะถูกสร้างใน database `company_db`)
    4. import ข้อมูลในไฟล์ employee_db.sql ลงใน `employee_db` และ import ข้อมูลใน company_db.sql ลงใน `company_db`

2.3 แก้ไขให้หน้า employee list และ employee form สำหรับสร้าง employee ใช้งานได้เหมือนเดิม (1 คะแนน)

**Hint:** สำหรับหน้า employee list จะเห็นว่าไม่มีข้อมูลใน columns `Depatment` และ `Position` เราจะต้องไป query มาเองเนื่องจากพอเป็นคนละ database ตัว Django จะไม่สามารถ join ให้อัตโนมัติได้ 

```python
# ตัวอย่างที่แทบจะเหมือนเฉลย...
employees = Employee.objects.all()
for employee in employees:
    employee.position = Position.objects.get(pk=employee.position_id)
```

**Hint:** สำหรับ `EmployeeForm` ที่ก่อนนี้สามารถแค่กำหนดใช้ field `position` ซึ่งเดิมเป็น `ForiegnKey` แล้ว form จะ render เป็น drop down list รายชื่อ position มาเลย ตอนนี้กลายเป็น `IntegerField` แล้ว ดังนั้นจะต้องใช้ `forms.ModelChoiceField`
