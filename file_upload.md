# File Uploads

Django จัดการ ไฟล์ file upload โดยบันทึกไว้ใน request.FILES 

## The Basics of File Upload With Django

[Ref](https://simpleisbetterthancomplex.com/tutorial/2016/08/01/how-to-upload-files-with-django.html)

ก่อนอื่นเราจะต้องเพิ่ม setting `MEDIA_URL` และ `MEDIA_ROOT`

```python
MEDIA_URL = '/media/'
MEDIA_ROOT = os.path.join(BASE_DIR, 'media')
```

## TOTURIAL

### Simple File Upload

เราสามารถจัดการ upload ไฟล์ได้ดัง code ต่อไปนี้

**upload_file/templates/simple_upload.html**

**IMPORTANT!!! ใน HTML ตัว tag `<form>` จะต้องเพิ่ม attribute `enctype="multipart/form-data"`**

```html
<form enctype="multipart/form-data" method="post" action="/foo/">
...
</form>
```

```html
{% load static %}
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8">
    <title>Simple File Upload</title>
  </head>
  <body>
  <form method="post" enctype="multipart/form-data">
    {% csrf_token %}
    <input type="file" name="myfile">
    <button type="submit">Upload</button>
  </form>

  {% if uploaded_file_url %}
    <p>File uploaded at: <a href="{{ uploaded_file_url }}">{{ uploaded_file_url }}</a></p>
  {% endif %}

  <p><a href="{% url 'home' %}">Return to home</a></p>
  </body>
</html>
```

**upload_file/views.py**

```python
from django.shortcuts import render
from django.conf import settings
from django.core.files.storage import FileSystemStorage

def simple_upload(request):
    if request.method == 'POST' and request.FILES['myfile']:
        myfile = request.FILES['myfile']
        fs = FileSystemStorage()
        filename = fs.save(myfile.name, myfile)
        uploaded_file_url = fs.url(filename)
        return render(request, 'core/simple_upload.html', {
            'uploaded_file_url': uploaded_file_url
        })
    return render(request, 'core/simple_upload.html')
```

### File Upload With Model Forms

เราสามารถ upload ไฟล์โดยใช้ ModelForm ซึ่งจะง่ายกว่ามาก

**upload_file/models.py**

```python
from django.db import models

class Document(models.Model):
    description = models.CharField(max_length=255, blank=True)
    document = models.FileField(upload_to='documents/')
    uploaded_at = models.DateTimeField(auto_now_add=True)
```

**upload_file/forms.py**

```python
from django import forms
from uploads.core.models import Document

class DocumentForm(forms.ModelForm):
    class Meta:
        model = Document
        fields = ('description', 'document', )
```

Form field ที่ใช้ในการบันทึก data ใน request.FILES คือ `FileField` หรือ `ImageField` (หรือ subclass ของ `FileField` หรือ `ImageField`)

```python
def model_form_upload(request):
    if request.method == 'POST':
        form = DocumentForm(request.POST, request.FILES)
        if form.is_valid():
            form.save()
            return redirect('home')
    else:
        form = DocumentForm()
    return render(request, 'core/model_form_upload.html', {
        'form': form
    })
```

นอกจากนั้นเรายังสามารถ upload ไฟล์ โดยกำหนด folder ได้ด้วย เช่น

```python
document = models.FileField(upload_to='documents/')
```

จากตัวอย่างนี้ไฟล์จะถูก upload ไปที่ `MEDIA_ROOT/documents/`

และยังสามารถกำหนด วันที่ปัจจุบันที่ upload เป็นชื่อ folder ได้

```python
document = models.FileField(upload_to='documents/%Y/%m/%d/')
```

จากตัวอย่างนี้ไฟล์จะถูก upload ไปที่ `MEDIA_ROOT/documents/2025/09/20`

และยังสามารถกำหนด property ของ instance ที่เกี่ยวข้อง เป็นชื่อ folder ได้

```python
def user_directory_path(instance, filename):
    # file will be uploaded to MEDIA_ROOT/user_<id>/<filename>
    return 'user_{0}/{1}'.format(instance.user.id, filename)

class MyModel(models.Model):
    upload = models.FileField(upload_to=user_directory_path)
```