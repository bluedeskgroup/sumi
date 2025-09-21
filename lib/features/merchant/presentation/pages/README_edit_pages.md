# صفحات تعديل المنتجات والخدمات - Edit Product & Service Pages

## الوصف
تطوير شامل لصفحات تعديل المنتجات والخدمات مع أزرار محسنة في صفحة المنتجات لتمييز المنتجات عن الخدمات.

## ✨ الميزات المضافة

### 🎯 **تحسينات صفحة المنتجات:**

#### **1. أزرار ذكية حسب النوع:**
```dart
// زر حذف ديناميكي
Text(
  product.type == ProductType.product ? 'حذف المنتج' : 'حذف الخدمة',
  style: TextStyle(color: Color(0xFFE32B3D)),
)

// زر تعديل ديناميكي  
Text(
  product.type == ProductType.product ? 'تعديل المنتج' : 'تعديل الخدمة',
  style: TextStyle(color: Color(0xFF9A46D7)),
)
```

#### **2. رسائل ديناميكية:**
```dart
// رسالة تأكيد الحذف
'هل أنت متأكد من حذف ${product.type == ProductType.product ? 'المنتج' : 'الخدمة'} "${product.name}"؟'

// رسالة النجاح
'تم حذف ${product.type == ProductType.product ? 'المنتج' : 'الخدمة'} بنجاح'

// رسالة الفشل
'فشل في حذف ${product.type == ProductType.product ? 'المنتج' : 'الخدمة'}'
```

#### **3. توجيه ذكي للتعديل:**
```dart
void _editProduct(ProductModel product) {
  if (product.type == ProductType.product) {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => EditProductPage(product: product),
    ));
  } else {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => EditServicePage(service: product),
    ));
  }
}
```

### 🎨 **صفحة تعديل المنتج:**

#### **التصميم المطابق للفيجما:**
- ✅ **Header مع العنوان والزر الخلفي**
- ✅ **صورة المنتج الحالية مع عنوان ديناميكي**
- ✅ **زر "تفاصيل المنتجات"**
- ✅ **قسم البيانات الأساسية**
- ✅ **قسم البيانات الإضافية**
- ✅ **أزرار الإجراءات**

#### **الحقول المتاحة:**
```dart
// البيانات الأساسية
- العنوان الرئيسي (إدخال نص)
- السعر (إدخال رقمي)  
- وصف بسيط (إدخال متعدد الأسطر)
- صور المنتج (4 خانات تحميل)

// البيانات الإضافية
- اختيار ماركة المنتج (قائمة منسدلة)
- التصنيف (قائمة منسدلة)
- كوبونات الخصم (قائمة منسدلة)
```

#### **المارق المتاحة:**
```dart
final List<String> _brands = [
  'Apple',
  'Samsung', 
  'Xiaomi',
  'هواوي',
  'أخرى',
];
```

#### **الفئات المتاحة:**
```dart
final List<String> _categories = [
  'إلكترونيات',
  'ملابس',
  'منزل ومطبخ',
  'رياضة', 
  'جمال وعناية',
  'كتب',
  'أخرى',
];
```

### 🛠️ **صفحة تعديل الخدمة:**

#### **التصميم المطابق للمنتج مع تخصيص للخدمات:**
- ✅ **Header مع عنوان "تعديل بيانات الخدمات والمنتجات"**
- ✅ **أيقونة خدمة بدلاً من صورة منتج**
- ✅ **زر "تفاصيل الخدمات"**
- ✅ **حقول مخصصة للخدمات**

#### **الحقول المخصصة للخدمات:**
```dart
// البيانات الأساسية
- العنوان الرئيسي (اسم الخدمة)
- السعر (سعر الخدمة)
- وصف بسيط (وصف الخدمة)
- صور الخدمة (4 خانات تحميل)

// البيانات الإضافية  
- اختيار مقدم الخدمة (بدلاً من الماركة)
- التصنيف (فئات خدمات)
- كوبونات الخصم
```

#### **مقدمو الخدمة:**
```dart
final List<String> _providers = [
  'الشركة الرئيسية',
  'مقدم خدمة مستقل',
  'شراكة خارجية',
  'فريق داخلي',
  'أخرى',
];
```

#### **فئات الخدمات:**
```dart
final List<String> _categories = [
  'خدمات تقنية',
  'خدمات منزلية', 
  'خدمات تعليمية',
  'خدمات صحية',
  'خدمات مالية',
  'خدمات استشارية',
  'أخرى',
];
```

## 🎨 **عناصر التصميم المطابقة للفيجما:**

### **🎯 الألوان:**
```dart
const Color(0xFF1D2035)    // النصوص الرئيسية
const Color(0xFF9A46D7)    // اللون البنفسجي الأساسي
const Color(0xFFFAF6FE)    // الخلفية البنفسجية الفاتحة
const Color(0xFFE7EBEF)    // الحدود والخطوط
const Color(0xFFDAE1E7)    // النصوص الثانوية
const Color(0xFF323F49)    // أيقونة الرجوع
const Color(0xFFAAB9C5)    // زر الإلغاء
const Color(0xFF4A5E6D)    // أيقونة القائمة المنسدلة
```

### **📝 الخطوط:**
```dart
// العناوين الرئيسية
fontFamily: 'Ping AR + LT'
fontWeight: FontWeight.w700
fontSize: 20

// التسميات
fontFamily: 'Ping AR + LT'
fontWeight: FontWeight.w500 
fontSize: 14

// النصوص
fontFamily: 'Ping AR + LT'
fontWeight: FontWeight.w500
fontSize: 16
```

### **📐 الأبعاد:**
```dart
// زر الرجوع
width: 55, height: 55
borderRadius: BorderRadius.circular(60)

// الحقول
borderRadius: BorderRadius.circular(16)
padding: EdgeInsets.symmetric(horizontal: 20, vertical: 18)

// الأزرار
height: 60
borderRadius: BorderRadius.circular(16)
```

## ⚡ **الوظائف المتقدمة:**

### **📸 تحميل الصور:**
```dart
Future<void> _pickImages() async {
  final List<XFile> images = await _imagePicker.pickMultiImage();
  if (images.isNotEmpty) {
    setState(() {
      _selectedImages = images.take(4).map((xFile) => File(xFile.path)).toList();
    });
  }
}
```

### **💾 حفظ التغييرات:**
```dart
Future<void> _saveChanges() async {
  // التحقق من صحة البيانات
  if (_nameController.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(/* رسالة خطأ */);
    return;
  }
  
  // إنشاء المنتج/الخدمة المحدثة
  final updatedProduct = ProductModel(/* البيانات المحدثة */);
  
  // حفظ في Firebase
  final success = await productService.updateProduct(updatedProduct);
  
  // عرض النتيجة
  if (success) {
    ScaffoldMessenger.of(context).showSnackBar(/* رسالة نجاح */);
    Navigator.of(context).pop();
  }
}
```

### **🔄 تهيئة الحقول:**
```dart
void _initializeFields() {
  _nameController.text = widget.product.name;
  _priceController.text = widget.product.originalPrice.toString();
  _descriptionController.text = widget.product.description;
  _selectedCategory = widget.product.category.isNotEmpty ? widget.product.category : null;
  // ... باقي الحقول
}
```

## 📱 **تجربة المستخدم:**

### **🎛️ التنقل:**
```
صفحة المنتجات
    ↓
[زر تعديل المنتج] → صفحة تعديل المنتج
[زر تعديل الخدمة] → صفحة تعديل الخدمة
    ↓
[زر التالى] → حفظ التغييرات والعودة
[زر الإلغاء] → العودة بدون حفظ
```

### **✅ التحقق من صحة البيانات:**
- ✅ **التحقق من وجود اسم المنتج/الخدمة**
- ✅ **التحقق من وجود السعر**
- ✅ **التحقق من صحة السعر (رقم)**
- ✅ **رسائل خطأ واضحة ومفيدة**

### **🔄 إدارة الحالة:**
```dart
bool _isLoading = false; // مؤشر التحميل

// أثناء الحفظ
setState(() => _isLoading = true);

// بعد انتهاء العملية
setState(() => _isLoading = false);
```

### **📱 واجهة متجاوبة:**
- ✅ **دعم RTL كامل للعربية**
- ✅ **تخطيط مرن مع `Expanded` و `ListView`**
- ✅ **أزرار متجاوبة مع التفاعل**
- ✅ **مؤشرات تحميل واضحة**

## 🛡️ **معالجة الأخطاء:**

### **🔧 الأخطاء المعالجة:**
```dart
// خطأ في اختيار الصور
try {
  final images = await _imagePicker.pickMultiImage();
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('حدث خطأ في اختيار الصور'))
  );
}

// خطأ في تحويل السعر
try {
  final price = double.parse(_priceController.text.trim());
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('يرجى إدخال سعر صحيح'))
  );
}

// فحص mounted قبل setState
if (mounted) {
  setState(() => _isLoading = false);
}
```

## 📂 **هيكل الملفات:**

```
lib/features/merchant/presentation/pages/
├── merchant_products_page.dart     # الصفحة الرئيسية (محدثة)
├── edit_product_page.dart          # صفحة تعديل المنتج (جديدة)
├── edit_service_page.dart          # صفحة تعديل الخدمة (جديدة)
└── README_edit_pages.md           # هذا التوثيق

assets/images/
├── edit_product_page/              # صور صفحة تعديل المنتج
└── edit_service_page/              # صور صفحة تعديل الخدمة
```

## 🎯 **المزايا الرئيسية:**

### **✨ للمطورين:**
- 🔄 **كود قابل للإعادة الاستخدام** بين المنتجات والخدمات
- 🧩 **هيكل معياري** سهل التطوير والصيانة
- 📝 **توثيق شامل** لجميع المكونات
- 🛡️ **معالجة أخطاء قوية** ومتسقة

### **📱 للمستخدمين:**
- 🎨 **تصميم احترافي** مطابق للفيجما 100%
- ⚡ **أداء سريع** مع تجربة سلسة
- 🧭 **تنقل بديهي** بين الصفحات
- ✅ **تحديث آمن** مع تأكيد العمليات

### **🔧 للنظام:**
- 🔗 **تكامل مثالي** مع `MerchantProductService`
- 💾 **حفظ موثوق** في Firebase
- 🔄 **تحديث فوري** للواجهة
- 🌐 **دعم كامل للـ RTL**

## 🚀 **الاستخدام:**

### **📋 لتعديل منتج:**
1. انتقل لصفحة المنتجات
2. اضغط "تعديل المنتج" على أي منتج
3. عدل البيانات المطلوبة  
4. اضغط "التالى" للحفظ

### **🛠️ لتعديل خدمة:**
1. انتقل لصفحة المنتجات
2. اضغط "تعديل الخدمة" على أي خدمة
3. عدل بيانات الخدمة
4. اضغط "التالى" للحفظ

---

**📍 الموقع**: `lib/features/merchant/presentation/pages/`  
**🔗 المرتبط بـ**: `MerchantProductService`, `ProductModel`, `ImagePicker`  
**🎨 التصميم**: مطابق لفيجما Sumi App - Edit Product/Service  
**📱 الإصدار**: محدث ومحسن 2024
