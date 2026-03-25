import 'package:flutter/material.dart';

class AppL10n {
  final Locale locale;

  const AppL10n(this.locale);

  static AppL10n of(BuildContext context) {
    return Localizations.of<AppL10n>(context, AppL10n) ??
        const AppL10n(Locale('ar'));
  }

  bool get isRTL => locale.languageCode == 'ar';
  bool get isAr => locale.languageCode == 'ar';

  static const Map<String, String> _ar = <String, String>{
    'app_title': 'ماجيك ستوديو',
    'app_subtitle': 'محرر صور احترافي',
    'welcome': 'مرحباً، أيها المبدع',
    'welcome_sub': 'أطلق العنان لإبداعك مع الذكاء الاصطناعي',
    'choose_studio': 'اختر مساحة عملك السحرية اليوم.',
    'loading': 'جاري التحميل...',
    'splash_tag': 'ذكاء اصطناعي · ألوان · سحر',
    'color_title': 'الألوان',

    // ─── Home Studios ─────────────────────────────────────────────
    'luma_title': 'Luma Master',
    'ai_manual_desc_short': 'تحكم يدوي في المناطق المتأثرة للذكاء الاصطناعي',
    'ref_short': 'REF',
    'quick_adj': 'تعديل سريع',
    'luma_desc': 'تعديل الألوان وسرقة الفلاتر بذكاء احترافي.',
    'pro_title': 'Pro Studio',
    'pro_desc': 'عزل ذكي، تأثيرات سايبر ونيون سينمائية.',
    'magic_title': 'Magic Eraser',
    'magic_desc': 'نموذج LLaMA للإزالة السحرية والرسم.',

    // ─── Picker ───────────────────────────────────────────────────
    'tap_to_open': 'اضغط لاختيار صورة',
    'pick_gallery': 'المعرض',
    'pick_camera': 'الكاميرا',
    'pick_hint': 'اختر صورة للبدء',
    'drop_hint': 'اسحب صورة هنا أو اضغط للتصفح',

    // ─── Editor ───────────────────────────────────────────────────
    'editor_title': 'التحرير',
    'filters': 'الفلاتر',
    'presets': 'القوالب',
    'adjust': 'تعديل',
    'tools': 'أدوات',
    'my_styles': 'أنماطي',
    'histogram': 'الرسم البياني',
    'scene': 'المشهد',
    'mood': 'المزاج',

    // ─── Adjustments ─────────────────────────────────────────────
    'brightness': 'السطوع',
    'contrast': 'التباين',
    'saturation': 'التشبع',
    'warmth': 'الدفء',
    'fade': 'تلاشي',
    'exposure': 'التعريض',
    'highlights': 'الإضاءات',
    'shadows': 'الظلال',
    'clarity': 'الوضوح',
    'dehaze': 'إزالة الضباب',
    'sharpen': 'الحدة',
    'vignette_size': 'التظليل',
    'tint': 'الصبغة',

    // ─── Tools ────────────────────────────────────────────────────
    'enhance': 'تحسين سحري',
    'random': 'عشوائي',
    'effects': 'تأثيرات',
    'overlays': 'طبقات',
    'copy': 'نسخ',
    'paste': 'لصق',
    'reset_all': 'إعادة الكل',
    'reset': 'إعادة ضبط',
    'compare': 'مقارنة',
    'undo': 'تراجع',
    'redo': 'إعادة',
    'clear': 'مسح',
    'import_presets': 'استيراد فلاتر',
    'export_presets': 'تصدير فلاتر',
    'steal_pro': 'سرقة الألوان',
    'save_style': 'حفظ النمط',
    'add_filter': 'إضافة فلتر',
    'create_filter': 'إنشاء فلتر',
    'filter_name': 'اسم الفلتر',
    'rename_style': 'إعادة تسمية النمط',
    'save_current_style': 'حفظ الستايل الحالي',
    'style_saved': 'تم حفظ الستايل في مكتبتك',

    // ─── Actions ─────────────────────────────────────────────────
    'save': 'حفظ',
    'share': 'مشاركة',
    'edit_again': 'تعديل مرة أخرى',
    'cancel': 'إلغاء',
    'retry': 'إعادة المحاولة',
    'search': 'ابحث عن فلتر...',
    'magic': 'سحر',
    'advanced': 'متقدم',
    'favorites': 'المفضلة',
    'all_filters': 'الكل',
    'cinema': 'سينما',
    'retro': 'ريترو',
    'pro_pack': 'برو',
    'ai_picks': 'اختيارات AI',
    'ai_assistant': 'مساعد الإبداع الذكي',
    'ai_loading': 'الذكاء الاصطناعي يحلل الصورة ويجهز لك اتجاها لونيا مناسبا...',
    'ai_apply': 'تطبيق الذكاء',
    'auto_ai': 'AI تلقائي',
    'ai_idle': 'الذكاء جاهز لبناء معالجة مناسبة لهذه الصورة.',
    'control_center': 'مركز التحكم',
    'ai_tab': 'AI',
    'ai_director': 'المخرج الذكي',
    'ai_ready': 'الاتجاه الإبداعي جاهز',
    'apply_direction': 'تطبيق الاتجاه',
    'recommended_presets': 'القوالب المقترحة',
    'quick_actions': 'أوامر سريعة',
    'lighting': 'الإضاءة',
    'focus': 'التركيز',
    'energy': 'الطاقة',
    'range': 'العمق',
    'smart_focus': 'تركيز ذكي',
    'cinema_boost': 'تعزيز سينمائي',
    'clean_pro': 'برو نظيف',
    'insight_pending': 'أضف صورة ليبدأ Pro Studio ببناء اتجاه إبداعي ذكي لها.',
    'ai_match': 'مطابقة AI',
    'ai_recommendations': 'الاقتراحات',
    'no_ai_recommendations': 'ستظهر اقتراحات الذكاء الاصطناعي بعد تحليل الصورة.',
    'run_ai': 'شغّل AI',
    'rerun_ai': 'أعد تشغيل AI',
    'ai_auto_fix': 'AI تلقائي',
    'ai_auto_applied': 'الذكاء الاصطناعي حسّن الصورة تلقائيًا',
    'ai_ready_short': 'جاهز',
    'ai_status_ready': 'AI جاهز',
    'ai_status_running': 'AI يعمل',
    'ai_status_loading_short': 'AI…',
    'ai_status_ready_short': 'AI ✓',
    'ai_status_idle_short': 'AI',
    'ai_manual': 'AI يدوي',
    'ai_report': 'تقرير AI',
    'ai_manual_title': 'المخرج الذكي يعمل عند الطلب',
    'ai_manual_desc':
        'اختر الصورة أولاً، ثم شغّل الذكاء الاصطناعي عندما تريد، وبعدها طبّق الاتجاه أو استخدم اللمسات الاحترافية السريعة.',
    'ai_no_image_desc':
        'افتح صورة أولاً لتفعيل المخرج الذكي، قراءة المشهد، مطابقة القوالب الاحترافية، وأدوات اللمسات النهائية.',
    'analyze_photo': 'حلّل الصورة',
    'ai_feature_scene': 'يفهم المشهد والإضاءة والمزاج وتوزيع العناصر.',
    'ai_feature_preset': 'يطابق الصورة مع اتجاهات احترافية جاهزة.',
    'ai_feature_finish': 'يضيف لمسات إنهاء راقية بعد التقرير.',
    'studio_control': 'لوحة الاستوديو',
    'live_preview': 'معاينة مباشرة',
    'active_look': 'الستايل الحالي',
    'preset_style': 'ستايل جاهز',
    'custom_style': 'ستايل مخصص',
    'studio_ready': 'جاهز للتطبيق الفوري',
    'looks_label': 'ستايل',
    'packs_label': 'باكات',
    'instant_apply': 'تطبيق فوري',
    'all_styles': 'كل الستايلات',
    'featured_drops': 'مختارات بارزة',
    'featured_drops_desc': 'أفضل الستايلات الجاهزة لتترك انطباعًا قويًا فورًا.',
    'core_presets': 'القوالب الأساسية',
    'core_presets_desc': 'قوالب آمنة وسريعة مبنية على محرك الاستوديو الرئيسي.',
    'curated_packs': 'الباكات المنسقة',
    'curated_packs_desc':
        'تصفح باكات مصممة للبورتريه، الليل، فلاش الفاشن، صناع المحتوى، المنتجات، السفر، والأنماط الحديثة.',
    'signature_library': 'مكتبة السيغنتشر',
    'signature_library_desc':
        'خزنة قوالب احترافية مصممة كخط إنتاج متكامل، تضم 140 ستايل مصقول مع باكات ترندية وتصفح سريع حسب الفئة.',
    'signature_library_count': 'ستايل جاهز',
    'preview_tools': 'أدوات المعاينة',
    'compare_hold': 'مقارنة',
    'random_mix': 'عشوائي',
    'cinematic_look': 'سينمائي',
    'depth_blur': 'عمق ناعم',
    'subject_mask_needed':
        'يلزم قناع موضوع موثوق لهذا التأثير، لذلك لم يتم تغيير الخلفية.',
    'prism_overlay': 'بريزم',
    'dust_overlay': 'غبار سينمائي',
    'overlay_finish_title': 'أوفرلايز إبداعية',
    'overlay_finish_desc': 'أضف طبقات فخمة بدون فرض قص الخلفية.',
    'background_optional': 'قص الخلفية اختياري فقط.',
    'tag_new': 'جديد',
    'tag_pro': 'احترافي',

    // ─── Status ───────────────────────────────────────────────────
    'saved': '✅ تم الحفظ في المعرض!',
    'save_failed': '❌ فشل الحفظ',
    'saved_ok': '✅ تم الحفظ في المعرض',
    'analyzing': 'جاري تحليل الصورة... 🧠',
    'style_applied': 'تم استخراج النمط وتطبيقه! 🎨',
    'processing': 'المعالجة',
    'uploading': 'رفع الصورة',
    'downloading': 'تحميل النتيجة',
    'failed': '❌ فشلت العملية',
    'timeout': '⏱️ انتهى الوقت',
    'permission_denied': '⚠️ الإذن مرفوض. فعّله من الإعدادات',

    // ─── Result Page ─────────────────────────────────────────────
    'result_title': 'النتيجة',
    'result_subtitle': 'تحفتك الفنية جاهزة',
    'result_save': 'حفظ في المعرض',
    'result_share': 'مشاركة',
    'result_edit': 'متابعة التعديل',
    'result_new': 'صورة جديدة',

    // ─── Effects ─────────────────────────────────────────────────
    'pro_studio_label': 'استوديو برو',
    'normal': 'طبيعي',
    'dreamy': 'حالم',
    'motion': 'حركة',
    'vintage': 'كلاسيكي',
    'noir': 'سينمائي',
    'neon': 'نيون',
    'cyber': 'سايبر',
    'sunset': 'غروب',
    'editorial': 'إديتوريال',
    'vaporwave': 'فايبور',
    'chrome': 'كروم',
    'halo': 'هالة',
    'mono_pop': 'مونو بوب',
    'street': 'ستريت',

    // ─── Misc ─────────────────────────────────────────────────────
    'change_lang': 'تغيير اللغة',
    'presets_quick': 'جاهز سريع',
    'brush': 'فرشاة',
    'eraser': 'ممحاة',
    'brush_size': 'حجم الفرشاة',
    'draw_first': '⚠️ ارسم الماسك أولاً',
    'no_styles': 'لا أنماط محفوظة بعد.\nطبّق فلتراً واحفظه!',
    'vignette': 'التظليل',
    'blur': 'تمويه',
    'aura': 'هالة',
    'grain': 'تحبيب',
    'scanlines': 'خطوط',
    'glitch': 'تشويش',
    'aura_color': 'لون الهالة',
    'ghost': 'شبح',
    'color_pop': 'إبراز اللون',
    'remove_bg': 'عزل الخلفية',
    'date_stamp': 'ختم التاريخ',
    'cinema_bar': 'شريط سينمائي',
    'polaroid': 'بولارويد',
    'light_leaks': 'تسرب الضوء',
    'none': 'بدون',
    'warm': 'افئ',
    'cool': 'بارد',
    'applying_magic': 'بناء المعالجة',
    'delete_style': 'حذف النمط',
    'delete_style_desc': 'سيتم إزالة هذا النمط المخصص من مكتبتك.',
    'delete': 'حذف',
    'style_renamed': 'تمت إعادة تسمية النمط',
    'style_deleted': 'تم حذف النمط',
    'queued': 'في الانتظار',
    'cancelled': 'تم الإلغاء',
    'magic_pick_headline': 'أزل العناصر المزعجة بدقة احترافية',
    'magic_pick_body':
        'أضف الصورة، ارسم فوق الجزء غير المرغوب، ودع النموذج يعيد بناء المشهد بشكل طبيعي.',
    'magic_pick_feature_precision': 'تحديد دقيق',
    'magic_pick_feature_speed': 'سير عمل سريع',
    'magic_pick_feature_quality': 'خروج احترافي',
    'workflow_upload': 'أضف الصورة',
    'workflow_mask': 'ارسم القناع',
    'workflow_render': 'ولّد المشهد النظيف',
    'editor_mask_ready': 'القناع جاهز',
    'editor_mask_pending': 'القناع بانتظار الرسم',
    'editor_brush_live': 'فرشاة مباشرة',
    'editor_workspace_fit': 'ملاءمة العرض',
    'editor_tip_precision':
        'كلما كان التحديد أدق كانت الحواف أنظف والنتيجة أكثر طبيعية.',
    'editor_tip_run':
        'ارسم فوق الجزء الذي تريد إزالته ثم شغّل السحر لتوليد النتيجة النظيفة.',
    'processing_headline': 'يجري تحسين المشهد بالذكاء الاصطناعي',
    'processing_body':
        'أبق هذه الشاشة مفتوحة بينما يعيد النموذج بناء الإطار النظيف.',
    'queue_position': 'الدور',
    'elapsed': 'الوقت',
    'job_id': 'المهمة',
    'return_editor': 'العودة للمحرر',
    'result_headline': 'النتيجة النظيفة أصبحت جاهزة',
    'result_body': 'عاين النتيجة النهائية، قارنها بالأصل، ثم صدّرها.',
    'result_compare_body':
        'حرّك المؤشر لمقارنة الصورة الأصلية بالنتيجة التي تم توليدها.',
    'compare_live': 'مقارنة مباشرة',
    'studio_quality': 'جودة احترافية',
    'new_project': 'مشروع جديد',
    'return_home': 'العودة للرئيسية',
    'resolution': 'الدقة',
    'original_label': 'الأصل',

    // Workspace & Studio specifics
    'lang_switch': 'English',
    'workspace_label': 'مساحة العمل',
    'workspace_hero_title': 'طوّر صورتك بخطوات إبداعية موجهة',
    'workspace_hero_sub':
        'أضف صورتك الأساسية، ثم المرجع، وبعدها فعّل الذكاء الاصطناعي أو حسّن القناع قبل التطبيق.',
    'workspace_tip': 'أداة الرسم تفتح فقط بعد تفعيل الذكاء الاصطناعي.',
    'workspace_need_reference_title': 'أضف صورة مرجعية',
    'workspace_need_reference_desc':
        'اختر مرجعاً بصرياً حتى يتمكن الاستوديو من بناء النتيجة ومطابقة الاتجاه المطلوب.',
    'workspace_result_ready_title': 'النتيجة جاهزة',
    'workspace_result_ready_desc':
        'يمكنك الحفظ أو المشاركة من الأعلى، أو العودة للوحة الأدوات إذا أردت صقلاً إضافياً.',
    'workspace_style_hint':
        'الأسلوب الحالي جاهز. راجع عناصر التحكم أو اضغط تطبيق لبدء المعالجة بهذا الاتجاه.',
    'status_ready': 'جاهز',
    'status_missing': 'ناقص',
    'editor_state_setup': 'إعداد',
    'editor_state_processing': 'جاري المعالجة',
    'editor_state_result': 'النتيجة جاهزة',
    'your_photo': 'صورتك',
    'filter_ref': 'الصورة المرجعية',
    'manual_select': 'تحسين القناع',
    'manual_locked': 'فعّل AI أولاً',
    'ai_mode_label': 'عزل ذكي بالذكاء الاصطناعي',
    'ai_mode_sub':
        'فعّل AI ثم افتح أداة الرسم لتحسين القناع قبل تطبيق المعالجة النهائية. إذا كان القناع ضعيفًا فسيتم تجاوزه لحماية الخلفية.',
    'style_label': 'الأسلوب البصري',
    'apply_btn': 'تطبيق المعالجة الآن',
    'add_photo_hint': 'أضف صورتك للبدء',
    'section_workflow': 'تسلسل العمل',
    'section_workflow_desc':
        'ابدأ بالصورة الأساسية، أضف المرجع، ثم فعّل العزل الذكي أو حسّن القناع قبل التطبيق.',
    'section_sources': 'المصادر',
    'section_sources_desc':
        'ابدأ بالصورة الأساسية ثم أضف المرجع الذي تريد نقل ألوانه أو طابعه.',
    'section_masking': 'العزل والقناع',
    'section_masking_desc':
        'فعّل العزل الذكي، ثم استخدم أداة الرسم لتحسين الحواف عندما تحتاج دقة إضافية.',
    'section_themes': 'الأساليب',
    'section_themes_desc':
        'اختر الأسلوب الأقرب للنتيجة التي تريدها قبل الانتقال إلى التعديلات الدقيقة.',
    'section_adjust': 'الضبط الدقيق',
    'section_adjust_desc':
        'افتح أي أداة لضبط القوة، التباين، اللون، والملمس النهائي بدون إرباك بصري.',
    'current_style_label': 'الأسلوب الحالي',
    'current_style_desc':
        'كل أسلوب يغيّر طريقة نقل الضوء واللون، وبعدها يمكنك صقل النتيجة يدوياً.',
    'current_style_ai_on': 'العزل الذكي مفعل لدعم معالجة أكثر وعياً بالموضوع',
    'current_style_ai_off': 'المعالجة ستعتمد على المرجع فقط بدون عزل ذكي',
    'workflow_step_photo': 'الصورة',
    'workflow_step_reference': 'المرجع',
    'workflow_step_mask': 'القناع',
    'workflow_step_apply': 'التطبيق',
    'workflow_workspace_ready': 'جاهز',
    'adjust_title': 'تحكم أدق في المعالجة',
    'adjust_desc':
        'اختر أي متغير لفتح أداة تحكم مركزة ثم عد مباشرة إلى بقية الإعدادات.',
    'adjust_active': 'تعديلات نشطة',
    'adjust_none': 'لا توجد تعديلات إضافية بعد',
    'apply_ready_hint':
        'الصورة والمرجع جاهزان. اضغط تطبيق لبدء المعالجة الحالية.',
    'apply_missing_hint': 'أدخل الصورة والمرجع أولاً لفتح زر التطبيق.',
    'apply_processing_hint':
        'يتم تنفيذ المعالجة الحالية. انتظر حتى تكتمل قبل إعادة المحاولة.',
    'manual_select_hint':
        'عندما يكون AI مفعلاً يمكنك تحسين حواف الموضوع يدوياً قبل التنفيذ النهائي.',
    'manual_ready': 'تم حفظ القناع اليدوي',
    'manual_draw': 'افتح الرسام لتحسين التحديد',
    'slider_strength': 'قوة المعالجة',
    'slider_skin': 'حماية البشرة',
    'slider_luma': 'نقل الإضاءة',
    'slider_color': 'نقل اللون',
    'slider_contrast': 'التباين السينمائي',
    'slider_vignette': 'تغميق الأطراف',
    'slider_grain': 'الحبيبات',
    'result_desc_long':
        'تم تجهيز النتيجة الجديدة. احفظها أو شاركها من الأعلى، أو عد للتعديل إذا أردت صقلاً إضافياً.',
    'result_actions_hint': 'الإخراج جاهز للمراجعة أو التصدير',
    'btn_edit': 'تعديل',
    'btn_compare': 'مقارنة',
    'btn_original': 'الأصل',
    'btn_share': 'مشاركة',
    'btn_save': 'حفظ الصورة',
    'btn_undo': 'رجوع',
    'btn_redo': 'إعادة',
    'btn_back': 'رجوع',
    'compare_hold_btn': 'اضغط مطولاً للمقارنة',
    'fullscreen_label': 'ملء الشاشة',
    'mask_title': 'محرر القناع الدقيق',
    'mask_ai_hint': 'تم تجهيز القناع الذكي. الفرشاة الآن جاهزة للتحسين.',
    'mask_not_found': 'لم يتم العثور على شخص واضح.',
    'mask_saving': 'جاري استخراج القناع...',
    'mask_error': 'خطأ في القناع',
    'mask_no_draw': 'شغّل AI أولاً ثم ارسم أو احفظ القناع.',
    'mask_booting': 'جاري تجهيز القناع الذكي...',
    'mask_unlock_hint': 'ابدأ بتحليل AI ثم استخدم الفرشاة لتنظيف الحواف بدقة.',
    'mask_ai_required': 'شغّل AI أولاً لفتح الفرشاة.',
    'mask_ready': 'الفرشاة جاهزة',
    'pan': 'تحريك',
    'snack_saving': 'جاري الحفظ...',
    'snack_saved': 'تم الحفظ بنجاح',
    'snack_save_fail': 'فشل الحفظ',
    'snack_preparing_share': 'جاري تجهيز الملف...',
    'snack_share_fail': 'فشلت المشاركة',
    'snack_no_output': 'لا يوجد ناتج بعد',
    'snack_need_both': 'يرجى إدراج صورتك والصورة المرجعية أولاً',
    'snack_need_target': 'يرجى إدراج صورتك أولاً',
    'snack_ai_conflict': 'فعّل AI أولاً لفتح أداة الرسم',
    'snack_processing': 'جاري المعالجة...',
    'snack_done': 'اكتملت المعالجة بنجاح',
    'snack_error_prefix': 'خطأ في المعالجة: ',
    'snack_received_mask': 'تم استلام القناع، جاري المعالجة...',
    'snack_no_person': 'تنبيه: لم يتم العثور على شخص واضح في الصورة.',
    'snack_ai_mask_skipped':
        'تم تجاوز العزل الذكي لأن جودة القناع لم تكن كافية، لذلك تم الحفاظ على الخلفية الأصلية.',
    'snack_convert_fail': 'فشل تحويل صيغة الصورة.',
    'proc_init': 'تجهيز محرك المعالجة...',
    'proc_extract': 'استخراج البصمة اللونية...',
    'proc_analyze': 'تحليل الطبقات والتفاصيل...',
    'proc_blend': 'مزج الإضاءة والظلال...',
    'proc_magic': 'تطبيق اللمسات النهائية...',
    'original_label_short': 'الأصل',
    'manual_tag': 'قناع يدوي',
    'stat_mask': 'القناع',
    'stat_mask_value': 'دقة بكسل',
    'stat_output': 'المخرج',
    'stat_output_value': 'تصدير نظيف',
    'breadcrumb_draw': 'رسم',
    'breadcrumb_remove': 'إزالة',
    'breadcrumb_done': 'تمام',
    'strokes': 'ضربات',
    'ready': 'جاهز',
    'mask': 'قناع',

    // New styles
    'style_luma_master': 'Luma Master',
    'style_pro_studio': 'Pro Studio',
    'style_color_theft': 'Color Theft',
    'style_theme_theft': 'Theme Theft',
    'style_cinematic': 'Cinematic',
    'style_cyber_neon': 'Cyber Neon',
    'style_color_splash': 'Color Splash',
    'style_hdr_magic': 'HDR Magic',
    'style_sepia_retro': 'Sepia Retro',

    // ─── Dashboard ────────────────────────────────────────────────
    'dashboard_welcome': 'مرحباً، صانع المحتوى',
    'dashboard_subtitle': 'اختر الاستوديو المناسب وابدأ بسرعة من شاشة رئيسية واحدة واضحة وسهلة.',
    'dashboard_eyebrow': 'لوحة الاستوديوهات',
    'dashboard_stats_title': 'كل أدواتك جاهزة في مكان واحد',
    'dashboard_stats_subtitle': 'تصميم متجاوب، وصول أسرع، وتجربة أوضح بين التحرير والذكاء الاصطناعي والرسم.',
    'dashboard_open': 'فتح الآن',
    'dashboard_ai_badge': 'جديد',
    'dashboard_luma_title': 'Luma Color',
    'dashboard_luma_desc': 'تصحيح ألوان متقدم، فلاتر، وتحكمات احترافية للصور بأسلوب منسق.',
    'dashboard_ai_title': 'AI Studio',
    'dashboard_ai_desc': 'نقل أسلوب ذكي مع قناع AI ورسّام تحسين للحواف داخل صفحة مستقلة.',
    'dashboard_pro_title': 'Pro Studio',
    'dashboard_pro_desc': 'تأثيرات احترافية ولمسات سينمائية بطابع قوي مناسب للمشاهد الإبداعية.',
    'dashboard_intel_title': 'تحليل موقع الصورة',
    'dashboard_intel_desc': 'افحص EXIF وGPS واستخرج النصوص والوجوه وافتح الإحداثيات مباشرة على الخريطة.',
    'dashboard_magic_title': 'Magic Eraser',
    'dashboard_magic_desc': 'إزالة العناصر غير المرغوبة والرسم على القناع لمعالجة الصورة بسهولة.',
    'dashboard_pill_responsive': 'متجاوب',
    'dashboard_pill_fast': 'سريع',
    'dashboard_pill_ai': 'ذكاء اصطناعي',

    // ─── Image Intel ──────────────────────────────────────────────
    'intel_page_title': 'تحليل موقع الصورة',
    'intel_page_headline': 'استخرج GPS إن وجد، ثم حلل النص والقرائن داخل الصورة لتقدير مكانها.',
    'intel_page_description':
        'هذه الصفحة تبحث أولًا عن إحداثيات EXIF، ثم تحاول استنتاج الموقع من النصوص والعناوين والمعالم الظاهرة، وتبني مستوى ثقة وأفضل نتيجة قابلة للفتح في Google Maps.',
    'intel_limitations_note':
        'مهم: بدون GPS أو نص واضح أو معلم معروف، النتيجة ستكون تقديرية فقط وليست دليلا قطعيا.',
    'intel_mobile_only': 'هذه الميزة تعمل حاليًا على Android و iPhone فقط.',
    'intel_analyze_existing': 'تحليل صورة موجودة',
    'intel_capture_with_gps': 'التقاط صورة جديدة مع GPS',
    'intel_location_service_off': 'خدمة الموقع مغلقة.',
    'intel_location_permission_denied': 'تم رفض صلاحية الموقع.',
    'intel_location_permission_denied_forever':
        'صلاحية الموقع مرفوضة نهائيًا من إعدادات الجهاز.',
    'intel_live_gps_warning':
        'تم استخدام GPS المباشر من الجهاز وقت الالتقاط، لكنه ليس مثبتًا داخل EXIF للصورة نفسها.',
    'intel_analysis_failed_prefix': 'فشل تحليل الصورة: ',
    'intel_map_open_failed': 'تعذر فتح الخريطة.',
    'intel_search_open_failed': 'تعذر فتح البحث.',
    'intel_mode_label': 'الوضع',
    'intel_location_mode_label': 'نوع التحديد',
    'intel_source_label': 'مصدر الموقع',
    'intel_confidence_label': 'مستوى الثقة',
    'intel_latitude_label': 'خط العرض',
    'intel_longitude_label': 'خط الطول',
    'intel_address_label': 'العنوان',
    'intel_best_query_label': 'أفضل استعلام للموقع',
    'intel_faces_label': 'الوجوه',
    'intel_blur_score_label': 'مؤشر الحدة',
    'intel_location_report_title': 'تقرير تحديد الموقع',
    'intel_ai_section_title': 'تحليل الذكاء الاصطناعي للمشهد',
    'intel_ai_confidence_label': 'ثقة الذكاء الاصطناعي',
    'intel_ai_scene_type_label': 'نوع المشهد',
    'intel_ai_best_guess_label': 'أفضل تخمين',
    'intel_ai_best_query_label': 'أفضل استعلام AI',
    'intel_open_exact_map': 'فتح الموقع على الخريطة',
    'intel_search_on_maps': 'بحث في Google Maps',
    'intel_search_web': 'بحث على الويب',
    'intel_location_clues_title': 'قرائن المكان',
    'intel_no_location_clues':
        'لم يتم العثور على قرائن مكانية كافية داخل الصورة.',
    'intel_ocr_title': 'النص المستخرج',
    'intel_no_text_found': 'لا يوجد نص واضح.',
    'intel_colors_title': 'الألوان',
    'intel_average_color_label': 'متوسط',
    'intel_top_color_label': 'بارز',
    'intel_exif_title': 'EXIF',
    'intel_not_available': 'غير متاح',
    'intel_exif_gps_clue_title': 'GPS داخل EXIF',
    'intel_exif_gps_clue_detail':
        'الصورة نفسها تحتوي على إحداثيات محفوظة داخل بياناتها.',
    'intel_live_gps_clue_title': 'GPS مباشر وقت الالتقاط',
    'intel_live_gps_clue_detail':
        'استخدم التطبيق موقع الجهاز لحظة التقاط الصورة الجديدة.',
    'intel_exif_text_clue_title': 'نصوص داخل EXIF',
    'intel_exif_text_clue_detail':
        'بعض الصور تحمل وصفًا أو تعليقًا قد يساعد في الاستدلال على المكان.',
    'intel_detected_text_clue_title': 'نص ظاهر في الصورة',
    'intel_detected_text_clue_detail':
        'النص المستخرج قد يحتوي على عنوان أو اسم مكان أو لافتة.',
    'intel_text_coordinates_clue_title': 'إحداثيات مكتوبة داخل الصورة',
    'intel_text_coordinates_clue_detail':
        'تم العثور على أرقام تبدو كإحداثيات داخل النص الظاهر على الصورة.',
    'intel_search_query_clue_title': 'أفضل عبارة بحث مكانية',
    'intel_search_query_clue_detail':
        'هذه أقوى عبارة يمكن إرسالها إلى Maps أو البحث العام.',
    'intel_geocoded_place_clue_title': 'مكان مطابق من النص',
    'intel_ai_scene_summary_clue_title': 'ملخص AI للمشهد',
    'intel_ai_scene_summary_clue_detail':
        'الذكاء الاصطناعي حاول قراءة المشهد نفسه من مبانٍ وطبيعة ومعالم.',
    'intel_ai_visual_clue_title': 'قرينة بصرية من AI',
    'intel_ai_visual_clue_detail':
        'هذه إشارة بصرية استنتجها النموذج من الصورة.',
    'intel_ai_location_guess_clue_title': 'تخمين AI للمكان',
    'intel_ai_location_guess_clue_detail':
        'أفضل مكان أو عبارة خرج بها النموذج من تحليل المشهد.',
    'intel_weak_clues_summary':
        'تم العثور على بعض القرائن، لكنها ليست كافية لتحديد المكان بثقة عالية.',
    'intel_no_location_summary':
        'لم يتم العثور على GPS أو نص أو قرائن مكانية كافية لتحديد مكان الصورة.',
    'intel_mode_existing': 'صورة موجودة',
    'intel_mode_capture': 'التقاط جديد مع GPS',
    'intel_loc_mode_exact': 'دقيق',
    'intel_loc_mode_estimated': 'تقديري',
    'intel_loc_mode_unknown': 'غير معروف',
    'intel_src_exif': 'GPS داخل الصورة',
    'intel_src_live': 'GPS الجهاز',
    'intel_src_text_coord': 'إحداثيات من النص',
    'intel_src_text_geocode': 'عنوان من النص',
    'intel_src_text_query': 'استعلام من النص',
    'intel_src_ai_scene': 'تحليل AI للمشهد',
    'intel_src_ai_query': 'استعلام AI',
    'intel_conf_vhigh': 'عالية جدًا',
    'intel_conf_high': 'عالية',
    'intel_conf_med': 'متوسطة',
    'intel_conf_low': 'ضعيفة',
    'intel_ai_ready': 'AI مفعّل وتم تحليل المشهد بصريًا.',
    'intel_ai_failed': 'تمت محاولة تحليل AI لكن الطلب فشل.',
    'intel_ai_disabled':
        'تحليل AI غير مفعّل. أضف OPENAI_API_KEY لتفعيل التعرف على المباني والطبيعة والمعالم.',

    // ─── Image Intel Parametric ───────────────────────────────────
    'intel_geocoded_place_clue_detail_param': 'تم تحويل النص "{query}" إلى مكان فعلي قابل للعرض على الخريطة.',
    'intel_exact_gps_summary_param': 'تم العثور على موقع دقيق من GPS داخل بيانات الصورة.{address}',
    'intel_live_gps_summary_param': 'تم تحديد الموقع بدقة من GPS الجهاز وقت الالتقاط.{address}',
    'intel_text_coordinates_summary_param': 'لا يوجد GPS مؤكد، لكن تم العثور على إحداثيات مكتوبة داخل الصورة{location}',
    'intel_text_geocode_summary_param': 'لا يوجد GPS مباشر، لكن النص الظاهر أعطى مكانًا محتملًا{location}',
    'intel_text_query_summary_param': 'تعذر تثبيت الموقع بدقة، لكن التطبيق استخرج عبارة بحث مكانية مفيدة{query}',
    'intel_ai_scene_summary_param': 'الذكاء الاصطناعي قرأ المشهد البصري ورجّح موقعًا محتملًا{label}',
    'intel_ai_scene_query_summary_param': 'الذكاء الاصطناعي لم يثبت إحداثيات دقيقة، لكنه قدّم عبارة مكانية قوية{query}',
    'intel_ai_supports_exact_summary_param': '{base} كما أن تحليل AI للمباني والطبيعة يدعم هذه النتيجة.',
  };

  static const Map<String, String> _en = <String, String>{
    'app_title': 'Magic Studio',
    'app_subtitle': 'Professional Photo Editor',
    'welcome': 'Welcome, Creator',
    'welcome_sub': 'Unleash your creativity with AI',
    'choose_studio': 'Choose your magic workspace today.',
    'loading': 'Loading...',
    'splash_tag': 'AI · Colors · Magic',
    'color_title': 'Color',

    // ─── Home Studios ─────────────────────────────────────────────
    'luma_title': 'Luma Master',
    'luma_desc': 'Color grading & smart filter stealing.',
    'pro_title': 'Pro Studio',
    'pro_desc': 'Smart isolation, Cyber & Neon effects.',
    'magic_title': 'Magic Eraser',
    'magic_desc': 'LLaMA model for magic removal & inpainting.',

    // ─── Picker ───────────────────────────────────────────────────
    'tap_to_open': 'Tap to Open Image',
    'pick_gallery': 'Gallery',
    'pick_camera': 'Camera',
    'pick_hint': 'Pick an image to start',
    'drop_hint': 'Drop image here or tap to browse',

    // ─── Editor ───────────────────────────────────────────────────
    'editor_title': 'Editor',
    'filters': 'Filters',
    'presets': 'Presets',
    'adjust': 'Adjust',
    'tools': 'Tools',
    'my_styles': 'My Styles',
    'histogram': 'Histogram',
    'scene': 'Scene',
    'mood': 'Mood',

    // ─── Adjustments ─────────────────────────────────────────────
    'brightness': 'Brightness',
    'contrast': 'Contrast',
    'saturation': 'Saturation',
    'warmth': 'Warmth',
    'fade': 'Fade',
    'exposure': 'Exposure',
    'highlights': 'Highlights',
    'shadows': 'Shadows',
    'clarity': 'Clarity',
    'dehaze': 'Dehaze',
    'sharpen': 'Sharpen',
    'vignette_size': 'Vignette',
    'tint': 'Tint',

    // ─── Tools ────────────────────────────────────────────────────
    'enhance': 'Enhance',
    'random': 'Random',
    'effects': 'Effects',
    'overlays': 'Overlays',
    'copy': 'Copy',
    'paste': 'Paste',
    'reset_all': 'Reset All',
    'reset': 'Reset',
    'compare': 'Compare',
    'undo': 'Undo',
    'redo': 'Redo',
    'clear': 'Clear',
    'import_presets': 'Import Presets',
    'export_presets': 'Export Presets',
    'steal_pro': 'Steal PRO Style',
    'save_style': 'Save Style',
    'add_filter': 'Add Filter',
    'create_filter': 'Create Filter',
    'filter_name': 'Filter name',
    'rename_style': 'Rename Style',
    'delete_style': 'Delete Style',
    'delete_style_desc': 'This custom style will be removed from your library.',
    'delete': 'Delete',
    'save_current_style': 'Save current style',
    'style_saved': 'Style saved to your library',
    'style_renamed': 'Style renamed',
    'style_deleted': 'Style deleted',

    // ─── Actions ─────────────────────────────────────────────────
    'save': 'Save',
    'share': 'Share',
    'edit_again': 'Edit Again',
    'cancel': 'Cancel',
    'retry': 'Retry',
    'search': 'Search filters...',
    'magic': 'Magic',
    'advanced': 'Advanced',
    'favorites': 'Favorites',
    'all_filters': 'All',
    'cinema': 'Cinema',
    'retro': 'Retro',
    'pro_pack': 'Pro Pack',
    'ai_picks': 'AI Picks',
    'ai_assistant': 'AI Creative Assistant',
    'ai_loading': 'AI is reading your photo and building a creative direction...',
    'ai_apply': 'Apply AI',
    'auto_ai': 'Auto AI',
    'ai_idle': 'AI is ready to build a look for this photo.',
    'control_center': 'Control Center',
    'ai_tab': 'AI',
    'ai_director': 'AI Director',
    'ai_ready': 'Creative direction is ready',
    'apply_direction': 'Apply Direction',
    'recommended_presets': 'Recommended presets',
    'quick_actions': 'Quick actions',
    'lighting': 'Lighting',
    'focus': 'Focus',
    'energy': 'Energy',
    'range': 'Range',
    'smart_focus': 'Smart Focus',
    'cinema_boost': 'Cinema Boost',
    'clean_pro': 'Clean Pro',
    'insight_pending': 'Import a photo to unlock AI scene planning for Pro Studio.',
    'ai_match': 'AI Match',
    'ai_recommendations': 'Recommendations',
    'no_ai_recommendations': 'AI recommendations will appear after the image is analyzed.',
    'run_ai': 'Run AI',
    'rerun_ai': 'Re-run AI',
    'ai_auto_fix': 'AI Auto Fix',
    'ai_auto_applied': 'AI auto-enhanced the photo',
    'ai_ready_short': 'Ready',
    'ai_status_ready': 'AI Ready',
    'ai_status_running': 'AI Running',
    'ai_status_loading_short': 'AI…',
    'ai_status_ready_short': 'AI ✓',
    'ai_status_idle_short': 'AI',
    'ai_manual_desc_short': 'Manual control over AI-affected areas',
    'ref_short': 'REF',
    'quick_adj': 'Quick Adjustment',
    'ai_manual': 'Manual AI',
    'ai_report': 'AI Report',
    'ai_manual_title': 'AI Director is on-demand',
    'ai_manual_desc':
        'Import your frame, launch AI when you are ready, then apply the direction or use premium finishing actions.',
    'ai_no_image_desc':
        'Open a photo first to unlock the AI director, scene breakdown, premium preset matching, and finishing actions.',
    'analyze_photo': 'Analyze Photo',
    'ai_feature_scene': 'Reads subject, mood, light, and scene balance.',
    'ai_feature_preset': 'Matches the frame to premium studio directions.',
    'ai_feature_finish': 'Adds clean finishing actions after the report.',
    'studio_control': 'Studio Control',
    'live_preview': 'Live Preview',
    'active_look': 'Active Look',
    'preset_style': 'Preset Style',
    'custom_style': 'Custom Style',
    'studio_ready': 'Studio ready for instant apply',
    'looks_label': 'Looks',
    'packs_label': 'Packs',
    'instant_apply': 'Instant Apply',
    'all_styles': 'All Styles',
    'featured_drops': 'Featured Drops',
    'featured_drops_desc': 'Hero looks curated to impress right away.',
    'core_presets': 'Core Presets',
    'core_presets_desc': 'Fast studio-safe looks powered by the main engine.',
    'curated_packs': 'Curated Packs',
    'curated_packs_desc':
        'Browse signature packs built for portraits, nightlife, fashion flash, creators, product polish, travel, and more.',
    'signature_library': 'Signature Library',
    'signature_library_desc':
        'A premium preset vault built like a product line, with 140 polished looks, trend-led packs, and fast category browsing.',
    'signature_library_count': 'styles ready',
    'preview_tools': 'Preview Tools',
    'compare_hold': 'Compare',
    'random_mix': 'Random Mix',
    'cinematic_look': 'Cinematic',
    'depth_blur': 'Depth Blur',
    'subject_mask_needed':
        'A reliable subject mask is required for this focus effect, so the background was left untouched.',
    'prism_overlay': 'Prism Overlay',
    'dust_overlay': 'Dust Overlay',
    'overlay_finish_title': 'Creative Overlays',
    'overlay_finish_desc':
        'Add premium overlay layers without forcing background cutout.',
    'background_optional': 'Background cutout stays optional.',
    'tag_new': 'NEW',
    'tag_pro': 'PRO',

    // ─── Status ───────────────────────────────────────────────────
    'saved': '✅ Saved to Gallery!',
    'save_failed': '❌ Save failed',
    'saved_ok': '✅ Saved to Gallery',
    'analyzing': 'Analyzing image... 🧠',
    'style_applied': 'Style extracted & applied! 🎨',
    'processing': 'Processing',
    'uploading': 'Uploading',
    'downloading': 'Downloading',
    'failed': '❌ Failed',
    'timeout': '⏱️ Timeout',
    'permission_denied': '⚠️ Permission denied. Enable in Settings.',

    // ─── Result Page ─────────────────────────────────────────────
    'result_title': 'Result',
    'result_subtitle': 'Your masterpiece is ready',
    'result_save': 'Save to Gallery',
    'result_share': 'Share',
    'result_edit': 'Continue Editing',
    'result_new': 'New Image',

    // ─── Effects ─────────────────────────────────────────────────
    'pro_studio_label': 'PRO STUDIO',
    'normal': 'Normal',
    'dreamy': 'Dreamy',
    'motion': 'Motion',
    'vintage': 'Vintage',
    'noir': 'Noir',
    'neon': 'Neon',
    'cyber': 'Cyber',
    'sunset': 'Sunset',
    'editorial': 'Editorial',
    'vaporwave': 'Vaporwave',
    'chrome': 'Chrome',
    'halo': 'Halo',
    'mono_pop': 'Mono Pop',
    'street': 'Street',

    // ─── Misc ─────────────────────────────────────────────────────
    'change_lang': 'Switch Language',
    'presets_quick': 'Quick Presets',
    'brush': 'Brush',
    'eraser': 'Eraser',
    'brush_size': 'Brush Size',
    'draw_first': '⚠️ Draw a mask first',
    'no_styles': 'No saved styles yet.\nApply a filter and save it!',
    'vignette': 'Vignette',
    'blur': 'Blur',
    'aura': 'Aura',
    'grain': 'Grain',
    'scanlines': 'Scanlines',
    'glitch': 'Glitch',
    'aura_color': 'Aura color',
    'ghost': 'Ghost',
    'color_pop': 'Color pop',
    'remove_bg': 'Remove BG',
    'date_stamp': 'Date stamp',
    'cinema_bar': 'Cinema bar',
    'polaroid': 'Polaroid',
    'light_leaks': 'Light leaks',
    'none': 'None',
    'warm': 'Warm',
    'cool': 'Cool',
    'applying_magic': 'Building the look',
    'queued': 'Queued',
    'cancelled': 'Cancelled',
    'magic_pick_headline': 'Remove distractions with studio-grade precision',
    'magic_pick_body':
        'Import a photo, paint over the unwanted area, and let the model rebuild the scene naturally.',
    'magic_pick_feature_precision': 'Precise masking',
    'magic_pick_feature_speed': 'Fast workflow',
    'magic_pick_feature_quality': 'Premium output',
    'workflow_upload': 'Upload image',
    'workflow_mask': 'Paint the mask',
    'workflow_render': 'Generate clean scene',
    'editor_mask_ready': 'Mask ready',
    'editor_mask_pending': 'Mask pending',
    'editor_brush_live': 'Live brush',
    'editor_workspace_fit': 'Fit view',
    'editor_tip_precision':
        'Use a tight mask for cleaner edges and more natural reconstruction.',
    'editor_tip_run':
        'Paint the area you want removed, then run Magic to generate the clean frame.',
    'processing_headline': 'Refining the scene with AI',
    'processing_body':
        'Keep this screen open while the model rebuilds the clean frame.',
    'queue_position': 'Queue',
    'elapsed': 'Elapsed',
    'job_id': 'Job',
    'return_editor': 'Back to editor',
    'result_headline': 'Your clean result is ready',
    'result_body':
        'Preview the final frame, compare it with the original, then export it.',
    'result_compare_body':
        'Drag the handle to compare the original frame against the regenerated result.',
    'compare_live': 'Live compare',
    'studio_quality': 'Studio quality',
    'new_project': 'New project',
    'return_home': 'Back home',
    'resolution': 'Resolution',
    'original_label': 'Original',

    // Workspace & Studio specifics
    'lang_switch': 'العربية',
    'workspace_label': 'Workspace',
    'workspace_hero_title': 'Shape your photo with guided creative editing',
    'workspace_hero_sub':
        'Add your main photo, load a reference, then enable AI or refine the mask before applying.',
    'workspace_tip': 'The painter unlocks only after AI mode is enabled.',
    'workspace_need_reference_title': 'Add a style reference',
    'workspace_need_reference_desc':
        'Load a reference image so the editor can build the result and match the intended direction.',
    'workspace_result_ready_title': 'Render ready',
    'workspace_result_ready_desc':
        'Save or share from the header, or head back into the tools for one more refinement pass.',
    'workspace_style_hint':
        'Your current look is ready. Review the controls or press apply to process with this direction.',
    'status_ready': 'Ready',
    'status_missing': 'Missing',
    'editor_state_setup': 'Setup',
    'editor_state_processing': 'Processing',
    'editor_state_result': 'Result Ready',
    'your_photo': 'Your Photo',
    'filter_ref': 'Style Reference',
    'manual_select': 'Refine Mask',
    'manual_locked': 'Enable AI first',
    'ai_mode_label': 'AI Smart Isolation',
    'ai_mode_sub':
        'Enable AI, then open the painter to refine the mask before the final render. If the mask is weak, the editor skips it to protect the background.',
    'style_label': 'Visual Style',
    'apply_btn': 'Apply Processing',
    'add_photo_hint': 'Add your photo to begin',
    'section_workflow': 'Workflow',
    'section_workflow_desc':
        'Load your photo, add a reference, then enable smart isolation or refine the mask before applying.',
    'section_sources': 'Sources',
    'section_sources_desc':
        'Start with the main photo, then add the visual reference that should guide the final look.',
    'section_masking': 'Masking',
    'section_masking_desc':
        'Enable smart isolation, then refine the edges manually whenever you need a cleaner subject.',
    'section_themes': 'Themes',
    'section_themes_desc':
        'Choose the closest look family before moving into detailed tuning.',
    'section_adjust': 'Adjustments',
    'section_adjust_desc':
        'Open any control to fine-tune strength, contrast, color transfer, and the finishing texture.',
    'line_strength': 'Strength',
    'line_skin': 'Skin Protect',
    'line_luma': 'Luma',
    'line_color': 'Color',
    'line_contrast': 'Contrast',
    'line_vignette': 'Vignette',
    'line_grain': 'Grain',
    'result_desc_long':
        'Your new render is ready. Save or share it from the header, or reopen the tools for another pass.',
    'result_actions_hint': 'Output ready for review or export',
    'btn_edit': 'Edit',
    'btn_compare': 'Compare',
    'btn_original': 'Original',
    'btn_share': 'Share',
    'btn_save': 'Save Photo',
    'btn_undo': 'Undo',
    'btn_redo': 'Redo',
    'btn_back': 'Back',
    'compare_hold_btn': 'Hold to Compare',
    'fullscreen_label': 'Fullscreen',
    'mask_title': 'Precision Mask Editor',
    'mask_ai_hint': 'AI mask ready. The brush is now unlocked.',
    'mask_not_found': 'No clear person detected.',
    'mask_saving': 'Extracting mask...',
    'mask_error': 'Mask error',
    'mask_no_draw': 'Run AI first, then paint or save the mask.',
    'mask_booting': 'Building the AI mask...',
    'mask_unlock_hint':
        'Start with AI analysis, then use the brush to clean the edges.',
    'mask_ai_required': 'Run AI first to unlock the brush.',
    'mask_ready': 'Brush unlocked',
    'pan': 'Pan',
    'snack_saving': 'Saving...',
    'snack_saved': 'Saved successfully',
    'snack_save_fail': 'Save failed',
    'snack_preparing_share': 'Preparing file...',
    'snack_share_fail': 'Share failed',
    'snack_no_output': 'No output yet',
    'snack_need_both': 'Please add your photo and the style reference first',
    'snack_need_target': 'Please add your photo first',
    'snack_ai_conflict': 'Enable AI mode first to unlock the painter',
    'snack_processing': 'Processing...',
    'snack_done': 'Processing complete',
    'snack_error_prefix': 'Processing error: ',
    'snack_received_mask': 'Mask received, processing...',
    'snack_no_person': 'Warning: No clear person found in your photo.',
    'snack_ai_mask_skipped':
        'AI isolation was skipped because the mask was not reliable enough, so the original background was preserved.',
    'snack_convert_fail': 'Image format conversion failed.',
    'proc_init': 'Initializing processing core...',
    'proc_extract': 'Extracting color fingerprint...',
    'proc_analyze': 'Analyzing layers and detail...',
    'proc_blend': 'Blending light and shadow...',
    'proc_magic': 'Applying final touches...',
    'original_label_short': 'Original',
    'manual_tag': 'Manual Mask',
    'stat_mask': 'Mask',
    'stat_mask_value': 'Pixel-accurate',
    'stat_output': 'Output',
    'stat_output_value': 'Clean export',
    'breadcrumb_draw': 'Draw',
    'breadcrumb_remove': 'Remove',
    'breadcrumb_done': 'Done',
    'strokes': 'strokes',
    'ready': 'Ready',
    'mask': 'Mask',

    // New styles
    'style_luma_master': 'Luma Master',
    'style_pro_studio': 'Pro Studio',
    'style_color_theft': 'Color Theft',
    'style_theme_theft': 'Theme Theft',
    'style_cinematic': 'Cinematic',
    'style_cyber_neon': 'Cyber Neon',
    'style_color_splash': 'Color Splash',
    'style_hdr_magic': 'HDR Magic',
    'style_sepia_retro': 'Sepia Retro',

    // ─── Dashboard ────────────────────────────────────────────────
    'dashboard_welcome': 'Welcome, Creator',
    'dashboard_subtitle': 'Choose the right studio and jump in quickly from one clean, easy home screen.',
    'dashboard_eyebrow': 'Studio Dashboard',
    'dashboard_stats_title': 'Everything is ready in one place',
    'dashboard_stats_subtitle': 'A more responsive layout, faster access, and a clearer flow across editing, AI, and painting.',
    'dashboard_open': 'Open Now',
    'dashboard_ai_badge': 'New',
    'dashboard_luma_title': 'Luma Color',
    'dashboard_luma_desc': 'Advanced color grading, filters, and polished photo controls in one workspace.',
    'dashboard_ai_title': 'AI Studio',
    'dashboard_ai_desc': 'Smart style transfer with AI masking and a dedicated edge-refine painter in its own page.',
    'dashboard_pro_title': 'Pro Studio',
    'dashboard_pro_desc': 'Bold cinematic effects and premium looks for more stylized creative work.',
    'dashboard_intel_title': 'Image Intel',
    'dashboard_intel_desc': 'Inspect EXIF and GPS, extract text and faces, and open coordinates directly on the map.',
    'dashboard_magic_title': 'Magic Eraser',
    'dashboard_magic_desc': 'Remove unwanted objects and paint on the mask to repair your image with ease.',
    'dashboard_pill_responsive': 'Responsive',
    'dashboard_pill_fast': 'Fast',
    'dashboard_pill_ai': 'AI Powered',

    // ─── Image Intel ──────────────────────────────────────────────
    'intel_page_title': 'Image Location Intel',
    'intel_page_headline':
        'Extract GPS when available, then analyze text and clues inside the image to estimate where it was taken.',
    'intel_page_description':
        'This page checks EXIF coordinates first, then tries to infer location from visible text, address fragments, and scene clues, producing a confidence score and the best Google Maps target.',
    'intel_limitations_note':
        'Important: without GPS, clear text, or a known landmark, the result remains an estimate rather than proof.',
    'intel_mobile_only': 'This feature currently works on Android and iPhone only.',
    'intel_analyze_existing': 'Analyze Existing Image',
    'intel_capture_with_gps': 'Capture New Image With GPS',
    'intel_location_service_off': 'Location service is turned off.',
    'intel_location_permission_denied': 'Location permission was denied.',
    'intel_location_permission_denied_forever':
        'Location permission was permanently denied in device settings.',
    'intel_live_gps_warning':
        'Live GPS from the device was used at capture time, but it is not confirmed inside the image EXIF itself.',
    'intel_analysis_failed_prefix': 'Image analysis failed: ',
    'intel_map_open_failed': 'Could not open the map.',
    'intel_search_open_failed': 'Could not open the search page.',
    'intel_mode_label': 'Mode',
    'intel_location_mode_label': 'Location mode',
    'intel_source_label': 'Location source',
    'intel_confidence_label': 'Confidence',
    'intel_latitude_label': 'Latitude',
    'intel_longitude_label': 'Longitude',
    'intel_address_label': 'Address',
    'intel_best_query_label': 'Best location query',
    'intel_faces_label': 'Faces',
    'intel_blur_score_label': 'Blur score',
    'intel_location_report_title': 'Location Report',
    'intel_ai_section_title': 'AI Scene Analysis',
    'intel_ai_confidence_label': 'AI confidence',
    'intel_ai_scene_type_label': 'Scene type',
    'intel_ai_best_guess_label': 'Best guess',
    'intel_ai_best_query_label': 'Best AI query',
    'intel_open_exact_map': 'Open Exact Map',
    'intel_search_on_maps': 'Search on Google Maps',
    'intel_search_web': 'Search the Web',
    'intel_location_clues_title': 'Location Clues',
    'intel_no_location_clues':
        'No strong location clues were found inside the image.',
    'intel_ocr_title': 'OCR Text',
    'intel_no_text_found': 'No clear text found.',
    'intel_colors_title': 'Colors',
    'intel_average_color_label': 'Average',
    'intel_top_color_label': 'Top',
    'intel_exif_title': 'EXIF',
    'intel_not_available': 'N/A',
    'intel_exif_gps_clue_title': 'GPS in EXIF',
    'intel_exif_gps_clue_detail':
        'The image itself contains coordinates stored in its metadata.',
    'intel_live_gps_clue_title': 'Live GPS at capture',
    'intel_live_gps_clue_detail':
        'The app used the device location at the moment of taking the new image.',
    'intel_exif_text_clue_title': 'Text inside EXIF',
    'intel_exif_text_clue_detail':
        'Some images include descriptions or comments that may help infer location.',
    'intel_detected_text_clue_title': 'Visible text in image',
    'intel_detected_text_clue_detail':
        'Extracted text may include an address, place name, or sign.',
    'intel_text_coordinates_clue_title': 'Coordinates written in image',
    'intel_text_coordinates_clue_detail':
        'The visible text contains numbers that look like latitude and longitude coordinates.',
    'intel_search_query_clue_title': 'Best location search phrase',
    'intel_search_query_clue_detail':
        'This is the strongest phrase that can be sent to Maps or web search.',
    'intel_geocoded_place_clue_title': 'Place matched from text',
    'intel_ai_scene_summary_clue_title': 'AI scene summary',
    'intel_ai_scene_summary_clue_detail':
        'The AI tried to read the scene itself from buildings, nature, and landmarks.',
    'intel_ai_visual_clue_title': 'AI visual clue',
    'intel_ai_visual_clue_detail':
        'This is a visual clue inferred by the model from the image.',
    'intel_ai_location_guess_clue_title': 'AI location guess',
    'intel_ai_location_guess_clue_detail':
        'The best place or query produced by the model from scene analysis.',
    'intel_weak_clues_summary':
        'Some clues were found, but they are not enough to identify the place with high confidence.',
    'intel_no_location_summary':
        'No GPS, text, or strong spatial clues were found to identify where the image was taken.',
    'intel_mode_existing': 'Existing image',
    'intel_mode_capture': 'New capture with GPS',
    'intel_loc_mode_exact': 'Exact',
    'intel_loc_mode_estimated': 'Estimated',
    'intel_loc_mode_unknown': 'Unknown',
    'intel_src_exif': 'Image EXIF GPS',
    'intel_src_live': 'Device GPS',
    'intel_src_text_coord': 'Coordinates from text',
    'intel_src_text_geocode': 'Address from text',
    'intel_src_text_query': 'Query from text',
    'intel_src_ai_scene': 'AI scene analysis',
    'intel_src_ai_query': 'AI scene query',
    'intel_conf_vhigh': 'Very high',
    'intel_conf_high': 'High',
    'intel_conf_med': 'Medium',
    'intel_conf_low': 'Low',
    'intel_ai_ready': 'AI is enabled and the scene was analyzed visually.',
    'intel_ai_failed': 'AI analysis was attempted but the request failed.',
    'intel_ai_disabled':
        'AI analysis is not enabled. Add OPENAI_API_KEY to enable building, nature, and landmark reasoning.',

    // ─── Image Intel Parametric ───────────────────────────────────
    'intel_geocoded_place_clue_detail_param': 'The text "{query}" was converted into a real place that can be shown on the map.',
    'intel_exact_gps_summary_param': 'An exact location was found from GPS metadata inside the image.{address}',
    'intel_live_gps_summary_param': 'The location was determined accurately from the device GPS at capture time.{address}',
    'intel_text_coordinates_summary_param': 'No confirmed GPS was found, but the image contains written coordinates{location}',
    'intel_text_geocode_summary_param': 'There is no direct GPS, but the visible text produced a likely place{location}',
    'intel_text_query_summary_param': 'An exact place could not be confirmed, but the app extracted a useful location query{query}',
    'intel_ai_scene_summary_param': 'The AI read the visual scene and suggested a likely place{label}',
    'intel_ai_scene_query_summary_param': 'The AI could not confirm exact coordinates, but it produced a strong location query{query}',
    'intel_ai_supports_exact_summary_param': '{base} The AI reading of buildings and natural cues also supports this result.',
  };

  String get(String key) {
    final map = locale.languageCode == 'en' ? _en : _ar;
    return map[key] ?? key;
  }


  // ─── Image Intel Helpers ──────────────────────────────────────
  String intelGeocodedPlaceClueDetail(String query) =>
      get('intel_geocoded_place_clue_detail_param').replaceAll('{query}', query);

  String intelExactGpsSummary(String? address) =>
      get('intel_exact_gps_summary_param').replaceAll(
        '{address}',
        address != null
            ? (isAr ? ' العنوان التقريبي: $address.' : ' Approximate address: $address.')
            : '',
      );

  String intelLiveGpsSummary(String? address) =>
      get('intel_live_gps_summary_param').replaceAll(
        '{address}',
        address != null
            ? (isAr ? ' العنوان التقريبي: $address.' : ' Approximate address: $address.')
            : '',
      );

  String intelTextCoordinatesSummary(String? locationLabel) =>
      get('intel_text_coordinates_summary_param').replaceAll(
        '{location}',
        locationLabel != null
            ? (isAr ? ' وتشير غالبًا إلى: $locationLabel.' : ' that likely point to: $locationLabel.')
            : '.',
      );

  String intelTextGeocodeSummary(String? locationLabel) =>
      get('intel_text_geocode_summary_param').replaceAll(
        '{location}',
        locationLabel != null ? (isAr ? ': $locationLabel.' : ': $locationLabel.') : '.',
      );

  String intelTextQuerySummary(String? query) =>
      get('intel_text_query_summary_param').replaceAll(
        '{query}',
        query != null ? (isAr ? ': $query.' : ': $query.') : '.',
      );

  String intelAiSceneSummary(String? label) =>
      get('intel_ai_scene_summary_param').replaceAll(
        '{label}',
        label != null ? (isAr ? ': $label.' : ': $label.') : '.',
      );

  String intelAiSceneQuerySummary(String? query) =>
      get('intel_ai_scene_query_summary_param').replaceAll(
        '{query}',
        query != null ? (isAr ? ': $query.' : ': $query.') : '.',
      );

  String intelAiSupportsExactSummary(String baseSummary) =>
      get('intel_ai_supports_exact_summary_param').replaceAll('{base}', baseSummary);

  String intelModeName(bool isExisting) =>
      get(isExisting ? 'intel_mode_existing' : 'intel_mode_capture');

  String intelLocationModeName(String mode) {
    switch (mode) {
      case 'exact':
        return get('intel_loc_mode_exact');
      case 'estimated':
        return get('intel_loc_mode_estimated');
      default:
        return get('intel_loc_mode_unknown');
    }
  }

  String intelLocationSourceName(String source) {
    switch (source) {
      case 'exif_gps':
        return get('intel_src_exif');
      case 'live_gps':
        return get('intel_src_live');
      case 'text_coordinates':
        return get('intel_src_text_coord');
      case 'text_geocode':
        return get('intel_src_text_geocode');
      case 'text_query':
        return get('intel_src_text_query');
      case 'ai_scene':
        return get('intel_src_ai_scene');
      case 'ai_scene_query':
        return get('intel_src_ai_query');
      default:
        return get('intel_loc_mode_unknown');
    }
  }

  String intelConfidenceName(double score) {
    if (score >= 0.9) return get('intel_conf_vhigh');
    if (score >= 0.7) return get('intel_conf_high');
    if (score >= 0.45) return get('intel_conf_med');
    return get('intel_conf_low');
  }

  String intelAiStatusLabel(String status) {
    switch (status) {
      case 'ready':
        return get('intel_ai_ready');
      case 'failed':
        return get('intel_ai_failed');
      default:
        return get('intel_ai_disabled');
    }
  }

  List<String> get processingPhrases => <String>[
        get('proc_init'),
        get('proc_extract'),
        get('proc_analyze'),
        get('proc_blend'),
        get('proc_magic'),
      ];
}

class AppL10nDelegate extends LocalizationsDelegate<AppL10n> {
  const AppL10nDelegate();

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en'].contains(
        locale.languageCode,
      );

  @override
  Future<AppL10n> load(Locale locale) async => AppL10n(locale);

  @override
  bool shouldReload(AppL10nDelegate old) => false;
}
