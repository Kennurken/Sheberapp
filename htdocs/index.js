(() => {
  const qs = (sel, root = document) => root.querySelector(sel);
  const qsa = (sel, root = document) => Array.from(root.querySelectorAll(sel));
  let generatedCode = null;
  const STORAGE = {
    user: 'sheber_user',
    theme: 'theme',
    lang: 'lang',
  };

  // =============================
  // I18N
  // =============================
  const I18N = {
    kk: {
      // base
      heroSub: 'Жылдам шебер табу сервисі',
      newService: 'Жаңа қызмет',
      urgentCall: 'Шұғыл шебер шақыру',
      urgentDesc: 'Сантехник немесе электрик 30 минут ішінде келеді.',
      findMaster: 'Шебер іздеу',
      activeOrder: 'Активті тапсырыс',
      contact: 'Хабарласу',
      categories: 'Категориялар',
      viewAll: 'Барлығы',
      catSan: 'Сантехник',
      catEl: 'Электрик',
      catClean: 'Тазалық',
      servicesCatalog: 'Қызметтер каталогы',
      servicesSub: 'Үй шаруасына қажетті шеберлер',
      messages: 'Хабарламалар',
      chatSub: 'Шеберлермен чат',
      profile: 'Жеке кабинет',
      profileSub: '',
      statOrder: 'Тапсырыс',
      statRating: 'Рейтинг',
      statBonus: 'Бонус',
      recentServices: 'Соңғы қызметтер',
      settings: 'Баптаулар',
      settingsSub: 'Қосымша параметрлер',
      darkMode: 'Түнгі режим',
      language: 'Тіл',
      home: 'Басты бет',
      searchPlaceholder: 'Қызмет түрін іздеу...',
      aiPlaceholder: 'Сұрағыңызды жазыңыз...',
      chat: 'Чат',
      chatInputPlaceholder: 'Хабарлама...',

      // errors
      err400Title: '400 — Қате сұрау',
      err400Desc: 'Сұрауыңыз дұрыс емес форматта жіберілді. Қайта тексеріп көріңіз.',
      err401Title: '401 — Авторизация қажет',
      err401Desc: 'Бұл бетке кіру үшін жүйеге кіріңіз.',
      err403Title: '403 — Рұқсат жоқ',
      err403Desc: 'Сізде бұл ресурсқа қолжеткізу құқығы жоқ.',
      err404Title: '404 — Бет табылмады',
      err404Desc: 'Сілтеме қате болуы мүмкін немесе бет өшірілген.',
      err503Title: '503 — Қызмет уақытша қолжетімсіз',
      err503Desc: 'Сервер уақытша жүктемеде немесе техникалық жұмыстар жүріп жатыр. Кейінірек қайталап көріңіз.',
      backHome: 'Басты бетке',
      tryAgain: 'Қайта көру',
      login: 'Кіру',
      goBack: 'Артқа',

      // roles/labels
      roleMaster: 'Шебер',
      roleClient: 'Клиент',
      profileDefaultUser: 'Пайдаланушы',
      profileUnknownCity: 'Қала белгісіз',
      yearsSuffix: 'жыл',

      // statuses
      statusNew: 'Жаңа',
      statusInProgress: 'Жұмыста',
      statusCompleted: 'Аяқталды',
      statusCancelled: 'Бас тартылды',

      // misc
      nothingFound: 'Ештеңе табылмады',
      ordersLoading: 'Жүктелуде...',
      noOrdersYet: 'Әзірге тапсырыс жоқ',

      // ===== added from index.php =====
      aiTitle: 'Sheber AI',
      aiWelcomeHtml: 'Сәлем! Мен Sheber.kz AI көмекшісімін.<br><br>Үйде не сынды? Мәселені жазсаңыз, шебер тауып беремін.',
      authCityPh: 'Қала',
      authEmailPh: 'Email',
      authLoginBtn: 'Кіру',
      authLoginTab: 'Кіру',
      authNamePh: 'Аты-жөні',
      authNote: '',
      authPasswordMinPh: 'Құпиясөз (мин. 6)',
      authPasswordPh: 'Құпиясөз',
      authPasswordRepeatPh: 'Қайталау',
      authRegBtn: 'Тіркелу',
      authRegTab: 'Тіркелу',
      authTag: 'Кіру / Тіркелу',
      demoActiveOrderStatus: 'Күйі: Шебер жолда (Ерлан Б.)',
      demoActiveOrderTitle: 'Кір жуғыш машина жөндеу',
      guest: 'Қонақ',
      modalOrderCreateAddrLabel: 'Мекенжай',
      useMyLocationBtn: "GPS арқылы анықтау",
      modalOrderCreateAddrPh: 'Мысалы: Астана, Мәңгілік Ел 10',
      modalOrderCreateDescLabel: 'Сипаттама',
      modalOrderCreateDescPh: 'Мәселені жазыңыз...',
      modalOrderCreateFootnote: '',
      modalOrderCreateHint: '* Нарықтық баға диапазоны көрсетіледі.',
      modalOrderCreatePriceLabel: 'Баға (₸)',
      modalOrderCreatePricePh: 'Мысалы: 5000',
      modalOrderCreateServiceLabel: 'Қызмет',
      modalOrderCreateServicePh: 'Мысалы: сантехника, электрика, жөндеу',
      modalOrderCreateSubmit: 'Жіберу',
      modalOrderCreateTitle: 'Тапсырыс жасау',
      needLogin: 'Кіру керек',
      pageTitle: 'Sheber.kz | Шебер іздеу',
      peBioPh: 'Өз мамандығым туралы бірнеше сөз...',
      peCityPh: 'Мысалы: Астана',
      peLabelAvatar: 'Аватар',
      peLabelBio: 'Өзім туралы',
      peLabelCity: 'Қала',
      peLabelExperience: 'Тәжірибе (жыл)',
      peLabelName: 'Аты',
      peLabelPhone: 'Телефон',
      peLabelProfession: 'Мамандығы',
      peNamePh: 'Аты-жөні',
      pePhonePh: '+7 (___) ___-__-__',
      peProfessionPh: 'Сантехник, электрик, тазалаушы...',
      peSaveBtn: 'Сақтау',
      peTitle: 'Профильді өңдеу',
      profInputTitle: 'Мамандығыңызды енгізіңіз',
      profInputDesc: 'Мастер ретінде тіркелу үшін мамандығыңызды көрсетіңіз.',
      profInputPlaceholder: 'Мысалы: Сантехник',
      profInputBtn: 'Жалғастыру',
      reviewBlockPlaceholder: 'Пікір жазыңыз...',
      reviewBlockSend: 'Пікір жіберу',
      reviewBlockTitle: 'Шеберге пікір қалдыру',
      settingsLoginAction: 'Кіру',
      settingsLogoutAction: 'Шығу',
      sidebarVersion: '  MILI-TECH - SHBER.KZ',
      support: 'Қолдау',
      supportHint: 'AI көмекшісін ашу үшін басыңыз',
      supportName: 'Sheber Қолдау',
      supportTime: 'AI',
      switchToClient: 'Клиентке өту',
      switchToMaster: 'Мастер болу',
      toastChatOpening: 'Чат ашылуда...',
      toastChooseCategory: 'Категорияны таңдаңыз',
      toastCleaning: 'Тазалық...',
      toastDefault: ' email н/се құпиясөз қате!',
      toastElectric: 'Электрика...',
      toastNotifOrderAccepted: 'Хабарламалар: Тапсырыс қабылданды',
      toastPlumbing: 'Сантехника...',
      // nav labels
      navHome: 'Басты',
      navChats: 'Чат',
      navMasters: 'Шеберлер',
      navProfile: 'Профиль',

      // security / profile
      securityTitle: 'Қауіпсіздік',
      verifyPhoneBtn: 'Нөмірді растау',
      masterProfileTitle: 'Шебер профилі',
      masterCallBtn: 'Қоңырау шалу',
      masterWaBtn: 'WhatsApp жазу',
      masterNoPhone: 'Байланыс мәліметтері жоқ',
      masterAvgRating: 'Орташа баға',
      masterExperience: 'Тәжірибе',
      masterAbout: 'Өзі туралы',
      masterCity: 'Қала',
      masterContacts: 'Байланыс',

      mastersTabTitle: 'Шеберлер',
      mastersTabSub: 'Таңдалған қала бойынша шеберлер тізімі',
      mastersSelectedCityLabel: 'Таңдалған қала',
      mastersChangeCityBtn: 'Қаланы өзгерту',
      mastersFilterTitle: 'Қаланы таңдаңыз',
      mastersFilterCityLabel: 'Қала',
      mastersFilterCityPlaceholder: '— Қаланы таңдаңыз —',
      mastersFilterHint: 'Таңдалған қаладағы тіркелген барлық шеберлерді көрсетеміз',
      mastersFilterSubmit: 'Шеберлерді көрсету',
      mastersChooseCityToast: 'Қаланы таңдаңыз',
      mastersLoading: 'Шеберлер жүктелуде...',
      mastersEmptyTitle: 'Шеберлер табылмады',
      mastersEmptyDesc: 'Бұл қалада тіркелген шеберлер әзірге жоқ.',
      mastersPromptTitle: 'Шебер іздеуді бастаңыз',
      mastersPromptDesc: 'Төмендегі «+» батырмасы арқылы қаланы таңдаңыз.',
      mastersCountFound: 'Табылды: {count}',
      mastersCountFoundInCity: '{city} қаласында {count} шебер табылды',
      mastersPhoneMissing: 'Телефон көрсетілмеген',
      mastersCallBtn: 'Қоңырау шалу',
      mastersWhatsAppBtn: 'WhatsApp',
      mastersAboutLabel: 'Өзі туралы',
      mastersExperienceLabel: 'Тәжірибе',
      mastersRatingLabel: 'Рейтинг',
      mastersSearchError: 'Шеберлер тізімін жүктеу мүмкін болмады',

      // orders
      orderOpenProfile: 'Профиль ашу',
      ordersLoginTitle: 'Тапсырыстарды көру үшін кіріңіз',
      ordersLoginDesc: 'Кіргеннен кейін тапсырыс жасап, шебермен чатта сөйлесе аласыз.',
      orderClientCreates: 'Тапсырысты клиент жасайды',
      needLoginFirst: 'Алдымен кіріңіз',
      orderFillDescAddr: 'Сипаттама мен мекенжайды толтырыңыз',
      orderPriceMin: 'Бағаны көрсетіңіз (ең азы 500 ₸)',
      orderCreated: 'Тапсырыс жасалды',
      orderCreateFail: 'Тапсырыс жасалмады',
      orderBadPrice: 'Баға диапазоннан тыс',
      orderChatOpenFail: 'Чат ашылмады',
      orderAccept: 'Қабылдау',
      orderAccepted: 'Тапсырыс қабылданды',
      orderNotNew: 'Тапсырыс жаңа емес',
      orderAcceptFail: 'Қабылдау мүмкін болмады',
      orderFinish: 'Аяқтау',
      orderFullyCompleted: 'Тапсырыс толық аяқталды',
      orderWaitSecondConfirm: 'Екінші тараптың растауы күтілуде',
      orderCannotFinishCancelled: 'Бас тартылған тапсырысты аяқтау мүмкін емес',
      orderFinishFail: 'Тапсырысты аяқтау мүмкін болмады',
      orderAlreadyClosed: 'Бұл тапсырыс жабылған',
      chatClosedForOrder: 'Бұл тапсырыс үшін чат жабық',
      messageNotSent: 'Хабарлама жіберілмеді',

      // reviews
      reviewLeave: 'Пікір қалдыру',
      reviewSend: 'Жіберу',
      reviewBodyPlaceholder: 'Пікір (міндетті емес)',
      reviewChooseRating: '1–5 баға таңдаңыз',
      reviewSaved: 'Рақмет! Пікір сақталды',
      reviewOnlyAfterCompleted: 'Пікір тек аяқталғаннан кейін',
      reviewAlreadyExists: 'Пікір бұрын қалдырылған',
      reviewSaveFail: 'Пікір сақталмады',
      reviewSent: 'Пікір жіберілді',
      orderNoSelected: 'Тапсырыс таңдалмаған',
      orderRatingRange: 'Баға 1..5',

      // profile edit
      avatarFileTooBig: 'Файл тым үлкен (макс 5мб)',
      avatarUpdated: 'Аватар жаңартылды!',
      avatarUploadFail: 'Қате: Аватар жүктелмеді',
      profileNameRequired: 'Атыңызды енгізіңіз',
      phoneBadFormat: 'Телефон форматы қате',
      profileSaved: '✅ Профиль сақталды',
      profileSaveFail: 'Сақталмады',

      // AI answers
      aiAskMore: 'Мәселені нақтырақ жазыңыз (қай жерде, не істемей тұр, шұғыл/жоспарлы).',
      aiToCatalogPlumbing: 'Бұл сантехникаға ұқсайды. **Қызметтер каталогы** → **Сантехника** бөлімін ашыңыз.',
      aiToCatalogElectric: 'Бұл электрикаға ұқсайды. **Қызметтер каталогы** → **Электрика** бөлімін ашыңыз.',
      aiToCatalogCleaning: 'Бұл тазалыққа ұқсайды. **Қызметтер каталогы** → **Тазалық** бөлімін ашыңыз.',
      aiTail: '<br><br>Қаласаңыз, қазір бірден **«Шебер іздеу»** батырмасын басыңыз.',

      // price hint
      orderPriceHintFormat: 'Ұсынылатын диапазон: {hint}',
    },

    ru: {
      heroSub: 'Сервис для быстрого поиска мастера',
      newService: 'Новая услуга',
      urgentCall: 'Срочно вызвать мастера',
      urgentDesc: 'Сантехник или электрик приедет в течение 30 минут.',
      findMaster: 'Найти мастера',
      activeOrder: 'Активный заказ',
      contact: 'Связаться',
      categories: 'Категории',
      viewAll: 'Все',
      catSan: 'Сантехник',
      catEl: 'Электрик',
      catClean: 'Уборка',
      servicesCatalog: 'Каталог услуг',
      servicesSub: 'Мастера для бытовых задач',
      messages: 'Сообщения',
      chatSub: 'Чат с мастерами',
      profile: 'Личный кабинет',
      profileSub: '',
      statOrder: 'Заказы',
      statRating: 'Рейтинг',
      statBonus: 'Бонус',
      recentServices: 'Последние услуги',
      settings: 'Настройки',
      settingsSub: 'Параметры приложения',
      darkMode: 'Ночной режим',
      language: 'Язык',
      home: 'Главная',
      searchPlaceholder: 'Поиск услуги...',
      aiPlaceholder: 'Напишите вопрос...',
      chat: 'Чат',
      chatInputPlaceholder: 'Сообщение...',

      err400Title: '400 — Неверный запрос',
      err400Desc: 'Запрос отправлен в неверном формате. Проверьте и повторите.',
      err401Title: '401 — Требуется вход',
      err401Desc: 'Чтобы открыть эту страницу, войдите в аккаунт.',
      err403Title: '403 — Доступ запрещён',
      err403Desc: 'У вас нет прав для доступа к этому ресурсу.',
      err404Title: '404 — Страница не найдена',
      err404Desc: 'Ссылка может быть неверной или страница удалена.',
      err503Title: '503 — Сервис временно недоступен',
      err503Desc: 'Сервер перегружен или идут технические работы. Попробуйте позже.',
      backHome: 'На главную',
      tryAgain: 'Повторить',
      login: 'Войти',
      goBack: 'Назад',

      roleMaster: 'Мастер',
      roleClient: 'Клиент',
      profileDefaultUser: 'Пользователь',
      profileUnknownCity: 'Город не указан',
      yearsSuffix: 'лет',

      statusNew: 'Новый',
      statusInProgress: 'В работе',
      statusCompleted: 'Завершено',
      statusCancelled: 'Отменено',

      nothingFound: 'Ничего не найдено',
      ordersLoading: 'Загрузка...',
      noOrdersYet: 'Пока нет заказов',

      // ===== added from index.php =====
      aiTitle: 'Sheber AI',
      aiWelcomeHtml: 'Привет! Я AI-помощник Sheber.kz.<br><br>Что сломалось дома? Опишите проблему — помогу найти мастера.',
      authCityPh: 'Город',
      authEmailPh: 'Email',
      authLoginBtn: 'Войти',
      authLoginTab: 'Войти',
      authNamePh: 'Имя',
      authNote: '',
      authPasswordMinPh: 'Пароль (мин. 6)',
      authPasswordPh: 'Пароль',
      authPasswordRepeatPh: 'Повторите',
      authRegBtn: 'Зарегистрироваться',
      authRegTab: 'Регистрация',
      authTag: 'Вход / Регистрация',
      demoActiveOrderStatus: 'Статус: мастер в пути (Ерлан Б.)',
      demoActiveOrderTitle: 'Ремонт стиральной машины',
      profInputTitle: 'Введите вашу профессию',
      profInputDesc: 'Чтобы стать мастером, укажите вашу профессию.',
      profInputPlaceholder: 'Например: Сантехник',
      profInputBtn: 'Продолжить',
      switchToClient: 'Стать клиентом',
      switchToMaster: 'Стать мастером',
      guest: 'Гость',
      modalOrderCreateAddrLabel: 'Адрес',
      useMyLocationBtn: "Определить по GPS",
      modalOrderCreateAddrPh: 'Например: Астана, Мәңгілік Ел 10',
      modalOrderCreateDescLabel: 'Описание',
      modalOrderCreateDescPh: 'Опишите проблему...',
      modalOrderCreateFootnote: '',
      modalOrderCreateHint: '* Покажем рекомендованный диапазон по рынку.',
      modalOrderCreatePriceLabel: 'Цена (₸)',
      modalOrderCreatePricePh: 'Например: 5000',
      modalOrderCreateServiceLabel: 'Услуга',
      modalOrderCreateServicePh: 'Например: сантехника, электрика, ремонт',
      modalOrderCreateSubmit: 'Отправить',
      modalOrderCreateTitle: 'Создать заказ',
      needLogin: 'Нужно войти',
      pageTitle: 'Sheber.kz | Найти мастера',
      peBioPh: 'Пара слов о себе и работе...',
      peCityPh: 'Например: Астана',
      peLabelAvatar: 'Аватар',
      peLabelBio: 'О себе',
      peLabelCity: 'Город',
      peLabelExperience: 'Стаж (лет)',
      peLabelName: 'Имя',
      peLabelPhone: 'Телефон',
      peLabelProfession: 'Профессия',
      peNamePh: 'Имя',
      pePhonePh: '+7 (___) ___-__-__',
      peProfessionPh: 'Сантехник, электрик, уборка...',
      peSaveBtn: 'Сохранить',
      peTitle: 'Редактировать профиль',
      reviewBlockPlaceholder: 'Напишите отзыв...',
      reviewBlockSend: 'Отправить отзыв',
      reviewBlockTitle: 'Оставить отзыв мастеру',
      settingsLoginAction: 'Войти',
      settingsLogoutAction: 'Выйти',
      sidebarVersion: '  MILI-TECH - SHBER.KZ',
      support: 'Поддержка',
      supportHint: 'Нажмите, чтобы открыть AI помощника',
      supportName: 'Поддержка Sheber',
      supportTime: 'AI',
      toastChatOpening: 'Открываем чат...',
      toastChooseCategory: 'Выберите категорию',
      toastCleaning: 'Уборка...',
      toastDefault: 'email или пароль неверный!',
      toastElectric: 'Электрика...',
      toastNotifOrderAccepted: 'Сообщения: заказ принят',
      toastPlumbing: 'Сантехника...',

      // nav labels
      navHome: 'Главная',
      navChats: 'Чаты',
      navMasters: 'Мастера',
      navProfile: 'Профиль',

      // security / master profile
      securityTitle: 'Безопасность',
      verifyPhoneBtn: 'Подтвердить номер',
      masterProfileTitle: 'Профиль мастера',
      masterCallBtn: 'Позвонить',
      masterWaBtn: 'Написать в WhatsApp',
      masterNoPhone: 'Контакты не указаны',
      masterAvgRating: 'Средняя оценка',
      masterExperience: 'Опыт работы',
      masterAbout: 'О себе',
      masterCity: 'Город',
      masterContacts: 'Контакты',

      mastersTabTitle: 'Мастера',
      mastersTabSub: 'Список мастеров по выбранному городу',
      mastersSelectedCityLabel: 'Выбранный город',
      mastersChangeCityBtn: 'Изменить город',
      mastersFilterTitle: 'Выберите город',
      mastersFilterCityLabel: 'Город',
      mastersFilterCityPlaceholder: '— Выберите город —',
      mastersFilterHint: 'Покажем всех зарегистрированных мастеров в выбранном городе',
      mastersFilterSubmit: 'Показать мастеров',
      mastersChooseCityToast: 'Выберите город',
      mastersLoading: 'Загружаем мастеров...',
      mastersEmptyTitle: 'Мастера не найдены',
      mastersEmptyDesc: 'В этом городе пока нет зарегистрированных мастеров.',
      mastersPromptTitle: 'Начните поиск мастера',
      mastersPromptDesc: 'Выберите город через кнопку «+» ниже.',
      mastersCountFound: 'Найдено: {count}',
      mastersCountFoundInCity: 'В городе {city} найдено мастеров: {count}',
      mastersPhoneMissing: 'Телефон не указан',
      mastersCallBtn: 'Позвонить',
      mastersWhatsAppBtn: 'WhatsApp',
      mastersAboutLabel: 'О себе',
      mastersExperienceLabel: 'Опыт',
      mastersRatingLabel: 'Рейтинг',
      mastersSearchError: 'Не удалось загрузить список мастеров',

      // orders
      orderOpenProfile: 'Открыть профиль',
      ordersLoginTitle: 'Войдите, чтобы видеть заказы',
      ordersLoginDesc: 'После входа вы сможете создавать заказы и переписываться с мастером.',
      orderClientCreates: 'Заказ создаёт клиент',
      needLoginFirst: 'Сначала войдите',
      orderFillDescAddr: 'Заполните описание и адрес',
      orderPriceMin: 'Укажите цену (минимум 500 ₸)',
      orderCreated: 'Заказ создан',
      orderCreateFail: 'Не удалось создать заказ',
      orderBadPrice: 'Цена вне допустимого диапазона',
      orderChatOpenFail: 'Не удалось открыть чат',
      orderAccept: 'Принять',
      orderAccepted: 'Заказ принят',
      orderNotNew: 'Заказ уже не новый',
      orderAcceptFail: 'Не удалось принять заказ',
      orderFinish: 'Завершить',
      orderFullyCompleted: 'Заказ полностью завершён',
      orderWaitSecondConfirm: 'Ожидаем подтверждения второй стороны',
      orderCannotFinishCancelled: 'Нельзя завершить отменённый заказ',
      orderFinishFail: 'Не удалось завершить заказ',
      orderAlreadyClosed: 'Этот заказ уже закрыт',
      chatClosedForOrder: 'Чат закрыт для этого заказа',
      messageNotSent: 'Сообщение не отправлено',

      // reviews
      reviewLeave: 'Оставить отзыв',
      reviewSend: 'Отправить',
      reviewBodyPlaceholder: 'Комментарий (необязательно)',
      reviewChooseRating: 'Выберите оценку 1–5',
      reviewSaved: 'Спасибо! Отзыв сохранён',
      reviewOnlyAfterCompleted: 'Отзыв можно оставить только после завершения',
      reviewAlreadyExists: 'Отзыв уже оставлен',
      reviewSaveFail: 'Не удалось сохранить отзыв',
      reviewSent: 'Отзыв отправлен',
      orderNoSelected: 'Нет выбранного заказа',
      orderRatingRange: 'Рейтинг 1..5',

      // profile edit
      avatarFileTooBig: 'Файл слишком большой (макс 5мб)',
      avatarUpdated: 'Аватар обновлён!',
      avatarUploadFail: 'Ошибка: не удалось загрузить аватар',
      profileNameRequired: 'Введите имя',
      phoneBadFormat: 'Неверный формат телефона',
      profileSaved: '✅ Профиль сохранён',
      profileSaveFail: 'Не удалось сохранить',

      // AI answers
      aiAskMore: 'Опишите проблему чуть подробнее (где, что именно, срочно/не срочно).',
      aiToCatalogPlumbing: 'Похоже на сантехнику. Откройте **Каталог услуг** → **Сантехника**.',
      aiToCatalogElectric: 'Похоже на электрику. Откройте **Каталог услуг** → **Электрика**.',
      aiToCatalogCleaning: 'Похоже на уборку. Откройте **Каталог услуг** → **Уборка**.',
      aiTail: '<br><br>Если хотите, нажмите **«Найти мастера»** прямо сейчас.',

      orderPriceHintFormat: 'Рекомендованный диапазон: {hint}',
    },
  };

  function getLang() {
    const v = (localStorage.getItem(STORAGE.lang) || 'kk').toLowerCase();
    return v === 'ru' ? 'ru' : 'kk';
  }

  function t(key) {
    return I18N[getLang()]?.[key] ?? key;
  }

  function tr(key, vars = {}) {
    let s = String(t(key));
    for (const [k, v] of Object.entries(vars || {})) {
      s = s.replaceAll('{' + k + '}', String(v));
    }
    return s;
  }

  function applyTranslations() {
    const lng = getLang();
    // text — use typeof check so empty string also clears placeholder dashes
    qsa('[data-key]').forEach((el) => {
      const key = el.dataset.key;
      const val = I18N[lng]?.[key];
      if (typeof val === 'string') el.textContent = val;
    });

    // html
    qsa('[data-html-key]').forEach((el) => {
      const key = el.dataset.htmlKey;
      const val = I18N[lng]?.[key];
      if (typeof val === 'string') el.innerHTML = val;
    });

    // placeholders
    qsa('[data-ph-key]').forEach((el) => {
      const key = el.dataset.phKey;
      const val = I18N[lng]?.[key];
      if (typeof val === 'string') el.placeholder = val;
    });

    // titles
    qsa('[data-title-key]').forEach((el) => {
      const key = el.dataset.titleKey;
      const val = I18N[lng]?.[key];
      if (typeof val === 'string') el.title = val;
    });

    // page title
    if (I18N[lng]?.pageTitle) document.title = t('pageTitle');
  }

  function showToast(message, timeout = 2200) {
    const toast = qs('#toast');
    if (!toast) return;

    toast.textContent = String(message);
    toast.classList.add('show');
    clearTimeout(showToast._t);
    showToast._t = setTimeout(() => toast.classList.remove('show'), timeout);
  }

  function setLanguage(lang, reload = false) {
    const normalized = (lang || '').toLowerCase() === 'ru' ? 'ru' : 'kk';
    localStorage.setItem(STORAGE.lang, normalized);
    // also sync cookie so PHP picks up the language on reload
    document.cookie = `lang=${normalized};path=/;max-age=31536000;samesite=lax`;

    if (reload) {
      const url = new URL(window.location.href);
      url.searchParams.set('lang', normalized);
      window.location.replace(url.toString());
      return;
    }

    const kkBtn = qs('#lang-kk');
    const ruBtn = qs('#lang-ru');
    if (kkBtn) kkBtn.classList.toggle('active', normalized === 'kk');
    if (ruBtn) ruBtn.classList.toggle('active', normalized === 'ru');

    applyTranslations();
    // re-render parts dependent on lang
    applyProfileStatsFromServer();
    renderProfileRecent();
    renderServices(qs('#courseSearch')?.value || '');
    renderMasterSearchResults();
  }

  // =============================
  // Theme
  // =============================
  function syncThemeToggle() {
    const html = document.documentElement;
    const saved = localStorage.getItem(STORAGE.theme);
    const theme = saved || html.getAttribute('data-theme') || 'light';
    html.setAttribute('data-theme', theme);
    // also sync cookie for PHP
    document.cookie = `theme=${theme};path=/;max-age=31536000;samesite=lax`;

    const cb = qs('#themeToggle');
    if (cb) cb.checked = theme === 'dark';
  }

  function toggleTheme() {
    const html = document.documentElement;
    const cur = html.getAttribute('data-theme') || 'light';
    const next = cur === 'dark' ? 'light' : 'dark';
    html.setAttribute('data-theme', next);
    localStorage.setItem(STORAGE.theme, next);
    syncThemeToggle();
  }

  // =============================
  // Menu / Tabs
  // =============================
  function toggleMenu() {
    const sidebar = qs('#sidebar');
    const overlay = qs('#overlay');
    if (sidebar) sidebar.classList.toggle('active');
    if (overlay) overlay.classList.toggle('active');
  }

  function setTab(tab) {
    const target = String(tab || 'home').toLowerCase();
    const tabs = ['home', 'courses', 'messages', 'profile', 'settings'];

    tabs.forEach((tname) => {
      const panel = qs(`#tab-${tname}`);
      if (panel) panel.classList.toggle('active', tname === target);

      const nav = qs(`#nav-${tname}`);
      if (nav) nav.classList.toggle('active', tname === target);
    });

    if (target === 'home') { window.scrollTo({ top: 0, behavior: 'smooth' }); renderMyOrders().catch(() => {}); }
    if (target === 'messages') loadOrdersList();
    if (target === 'courses') renderMasterSearchResults();
  }

  function primaryAction() {
    openCreateOrder();
  }

  // =============================
  // User
  // =============================
  function getLocalUser() {
    try {
      return JSON.parse(localStorage.getItem(STORAGE.user) || 'null');
    } catch {
      return null;
    }
  }

  function loadUser() {
    const u = getLocalUser();
    const lang = getLang();

    const name = u?.name || t('profileDefaultUser');
    const city = u?.city || t('profileUnknownCity');
    const roleLabel = u?.role === 'master' ? t('roleMaster') : t('roleClient');
    const initial = String(name).trim().charAt(0).toUpperCase() || 'A';

    const greetElement = qs('#greetingH1');
    if (greetElement) {
      if (u) {
        greetElement.textContent = (lang === 'ru') ? `Привет, ${name}! ` : `Сәлем, ${name}! `;
      } else {
        greetElement.textContent = (lang === 'ru') ? 'Привет! ' : 'Сәлем! ';
      }
    }

    const profName = qs('#profileName');
    const profRole = qs('#profileRole');
    const profAvat = qs('#profileAvatar');
    if (profName) profName.textContent = name;
    if (profRole) profRole.textContent = u ? `${roleLabel} • ${city}` : '';
    if (profAvat && !u?.avatar_url) profAvat.textContent = initial;

    const sideName = qs('#sideName');
    const sideRole = qs('#sideRole');
    const sideAvat = qs('#sideAvatar');
    if (sideName) sideName.textContent = u ? name : t('guest');
    if (sideRole) sideRole.textContent = u ? `${roleLabel} • ${city}` : t('needLogin');
    if (sideAvat && !u?.avatar_url) sideAvat.textContent = initial;

    // titles
    applyTranslations();
  }

  function logout() {
    localStorage.removeItem(STORAGE.user);
    window.location.href = 'logout.php';
  }

  async function switchRole(targetRole) {
    try {
      const u = getLocalUser();

      if (targetRole === 'master') {
        if (!u || !u.profession || u.profession.trim() === '') {
          // Instead of prompt, open custom modal
          closeProfileEdit(); // Ensure profile modal is closed before opening this one
          const rpm = qs('#roleProfessionModal');
          const rpo = qs('#roleProfessionOverlay');
          if (rpm) rpm.classList.add('active');
          if (rpo) rpo.classList.add('active');
          return; // The actual switchRole will be called by roleProfessionSubmit
        }
      }

      await executeRoleSwitch(targetRole, "");

    } catch (e) {
      showToast(e.message || "Failed to switch role");
    }
  }

  window.closeRoleProfessionModal = function () {
    const m = qs('#roleProfessionModal');
    const o = qs('#roleProfessionOverlay');
    if (m) m.classList.remove('active');
    if (o) o.classList.remove('active');
  };

  window.roleProfessionSubmit = async function () {
    const profInput = qs('#roleProfessionInput');
    const prof = profInput ? profInput.value.trim() : "";

    if (!prof) {
      showToast(getLang() === 'ru' ? "Пожалуйста, введите профессию" : "Мамандықты енгізіңіз");
      return;
    }

    closeRoleProfessionModal();

    try {
      await executeRoleSwitch('master', prof);
    } catch (e) {
      showToast(e.message || "Failed to switch role");
    }
  };

  async function executeRoleSwitch(targetRole, professionOverride) {
    const u = getLocalUser();
    const payload = { target_role: targetRole };
    if (professionOverride) payload.profession = professionOverride;

    await apiPost("api/role_switch.php", payload);

    if (u) {
      u.role = targetRole;
      if (professionOverride) u.profession = professionOverride;
      localStorage.setItem(STORAGE.user, JSON.stringify(u));
    }

    if (targetRole === 'master') {
      window.location.href = 'home-master.php';
    } else {
      window.location.href = 'index.php';
    }
  }

  // =============================
  // POST-LOGIN SMS VERIFICATION
  // =============================
  let verifyTimerInterval = null;

  window.handleSendVerificationCode = async function () {
    const btn = qs('#btn-verify-send');
    const input = qs('#verifyPhoneInput');
    
    if (!btn || !input) return console.error("Ошибка: Элементы не найдены!");

    const phoneInput = input.value.trim();
    if (phoneInput.length < 10) return alert(getLang() === 'ru' ? 'Введите корректный номер' : 'Дұрыс нөмір енгізіңіз');

    // --- Нормализация номера (твоя лучшая версия) ---
    let cleanPhone = phoneInput.replace(/\D/g, '');
    if (cleanPhone.startsWith('87')) cleanPhone = '7' + cleanPhone.slice(1);
    const fullPhone = cleanPhone.startsWith('+') ? cleanPhone : '+' + cleanPhone;

    btn.disabled = true;
    btn.innerText = getLang() === 'ru' ? 'Отправка...' : 'Жіберілуде...';

    try {
        const params = new URLSearchParams();
        params.append('phone', fullPhone);
        params.append('action', 'send'); // Указываем действие для прокси

        const response = await fetch('api/proxy_send.php', {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
            body: params
        });

        // Проверяем, что сервер вернул именно JSON
        const contentType = response.headers.get("content-type");
        if (!contentType || !contentType.includes("application/json")) {
            throw new Error("Сервер вернул не JSON, а HTML. Проверь прокси!");
        }

        const data = await response.json();

        if (data.success) {
            // ВАЖНО: Сохраняем код в переменную
            generatedCode = String(data.verificationCode);
            console.log("Код успешно получен от Vercel");

            // UI логика
            const displayEl = qs('#verify-display-phone');
            if (displayEl) displayEl.innerText = fullPhone;
            
            if (qs('#sms-step-phone')) qs('#sms-step-phone').style.display = 'none';
            if (qs('#sms-step-code')) qs('#sms-step-code').style.display = 'block';

            if (typeof startVerifyTimer === 'function') {
                startVerifyTimer(data.expiresIn || 180);
            }

            const firstInput = qs('#verify-code-inputs input:first-child');
            if (firstInput) firstInput.focus();

        } else {
            alert((getLang() === 'ru' ? 'Ошибка: ' : 'Қате: ') + (data.error || 'Ошибка отправки'));
        }
    } catch (e) {
        console.error("SMS Auth Error:", e);
        alert(getLang() === 'ru' ? 'Ошибка соединения с сервером' : 'Сервермен байланыс қатесі');
    } finally {
        btn.disabled = false;
        btn.innerText = (getLang() === 'ru' ? 'Получить код' : 'Код алу');
    }
};
  window.handleVerifyAccountCode = async function () {
    const inputs = qs('#verify-code-inputs').querySelectorAll('input');
    // Собираем код и убираем пробелы
    const userCode = Array.from(inputs).map(i => i.value.trim()).join('');
    
    // Получаем номер и очищаем его для сохранения в БД
    let phoneRaw = qs('#verify-display-phone').innerText;
    const phone = phoneRaw.replace(/\D/g, ''); 

    // Базовая проверка ввода
    if (userCode.length < 4) {
        return alert(getLang() === 'ru' ? 'Введите полный код' : 'Толық кодты енгізіңіз');
    }

    const btn = qs('#btn-verify-confirm');
    if (btn) {
        btn.disabled = true;
        btn.innerText = getLang() === 'ru' ? 'Проверка...' : 'Тексерілуде...';
    }

    try {
        // --- ШАГ 1: ЛОКАЛЬНАЯ ПРОВЕРКА (БЕЗ REDIS) ---
        // Сравниваем введенный код с тем, что прислал Vercel при отправке СМС
        if (userCode !== String(generatedCode)) {
            alert(getLang() === 'ru' ? 'Неверный код' : 'Қате код');
            // Возвращаем кнопку в рабочее состояние
            if (btn) {
                btn.disabled = false;
                btn.innerText = getLang() === 'ru' ? 'Подтвердить' : 'Растау';
            }
            return;
        }

        // --- ШАГ 2: СОХРАНЕНИЕ В ТВОЮ БД ---
        // Если коды совпали, отправляем данные в твой локальный save_phone.php
        const saveRes = await fetch('api/save_phone.php', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ phone })
        });

        // Проверяем, что ответ от save_phone.php — это JSON
        const contentType = saveRes.headers.get("content-type");
        if (!contentType || !contentType.includes("application/json")) {
            throw new Error("Ошибка сервера БД: получен не JSON");
        }

        const saveData = await saveRes.json();

        if (saveData.success) {
            alert(getLang() === 'ru' ? 'Номер успешно подтверждён!' : 'Нөмір сәтті расталды!');
            // Очищаем код из памяти в целях безопасности
            generatedCode = null; 
            window.location.href = 'index.php?tab=profile&auth=login_ok';
        } else {
            alert(saveData.error || 'Ошибка сохранения в БД');
        }

    } catch (e) {
        console.error("Критическая ошибка в handleVerifyAccountCode:", e);
        alert(getLang() === 'ru' ? 'Ошибка соединения или сервера' : 'Байланыс немесе сервер қатесі');
    } finally {
        if (btn) {
            btn.disabled = false;
            btn.innerText = getLang() === 'ru' ? 'Подтвердить' : 'Растау';
        }
    }
};

  window.startVerifyTimer = function (seconds) {
    const display = qs('#verify-timer-count');
    if (!display) return;

    let timer = seconds;
    if (verifyTimerInterval) clearInterval(verifyTimerInterval);

    verifyTimerInterval = setInterval(() => {
      timer--;
      display.innerText = timer;
      if (timer <= 0) clearInterval(verifyTimerInterval);
    }, 1000);
  };

  window.resetVerifySteps = function () {
    qs('#sms-step-phone').style.display = 'block';
    qs('#sms-step-code').style.display = 'none';
    if (verifyTimerInterval) clearInterval(verifyTimerInterval);
  };

  // Add event listeners for code inputs jumping
  document.addEventListener('DOMContentLoaded', () => {
    const inputs = document.querySelectorAll('.code-input');
    inputs.forEach((input, idx) => {
      input.addEventListener('input', (e) => {
        if (e.target.value && idx < inputs.length - 1) {
          inputs[idx + 1].focus();
        }
      });
      input.addEventListener('keydown', (e) => {
        if (e.key === 'Backspace' && !e.target.value && idx > 0) {
          inputs[idx - 1].focus();
        }
      });
    });
  });

  // =============================
  // Services
  // =============================
  const SERVICES = [
    {
      titleKk: 'Сантехника',
      titleRu: 'Сантехника',
      subtitleKk: 'Кран, құбыр, унитаз',
      subtitleRu: 'Кран, трубы, сантехника',
      items: [
        { kk: 'Кран жөндеу', ru: 'Ремонт крана', metaKk: 'Орташа 30–60 мин', metaRu: 'В среднем 30–60 мин' },
        { kk: 'Құбыр тазалау', ru: 'Прочистка труб', metaKk: 'Шұғыл/Жоспарлы', metaRu: 'Срочно/Планово' },
        { kk: 'Су ағуын тоқтату', ru: 'Устранение протечки', metaKk: 'Жедел көмек', metaRu: 'Срочная помощь' },
      ],
    },
    {
      titleKk: 'Электрика',
      titleRu: 'Электрика',
      subtitleKk: 'Розетка, жарық, автомат',
      subtitleRu: 'Розетки, свет, автоматы',
      items: [
        { kk: 'Розетка ауыстыру', ru: 'Замена розетки', metaKk: '20–40 мин', metaRu: '20–40 мин' },
        { kk: 'Жарық шам орнату', ru: 'Установка светильника', metaKk: '30–60 мин', metaRu: '30–60 мин' },
        { kk: 'Қысқа тұйықталу', ru: 'Короткое замыкание', metaKk: 'Шұғыл', metaRu: 'Срочно' },
      ],
    },
    {
      titleKk: 'Тазалық',
      titleRu: 'Уборка',
      subtitleKk: 'Үй жинау, терезе жуу',
      subtitleRu: 'Квартира, окна',
      items: [
        { kk: 'Жалпы тазалау', ru: 'Генеральная уборка', metaKk: '2–4 сағ', metaRu: '2–4 ч' },
        { kk: 'Терезе жуу', ru: 'Мойка окон', metaKk: '1–2 сағ', metaRu: '1–2 ч' },
        { kk: 'Кілем жуу', ru: 'Чистка ковров', metaKk: 'Жеткізу бар', metaRu: 'Есть доставка' },
      ],
    },
  ];

  function toggleAccordion(headEl) {
    const acc = headEl?.closest?.('.course-accordion');
    if (!acc) return;
    acc.classList.toggle('open');
  }

  function renderServices(query = '') {
    const root = qs('#coursesRoot');
    if (!root) return;

    const q = String(query || '').trim().toLowerCase();
    const lang = getLang();

    const blocks = SERVICES.map((cat, idx) => {
      const title = lang === 'ru' ? cat.titleRu : cat.titleKk;
      const subtitle = lang === 'ru' ? cat.subtitleRu : cat.subtitleKk;

      const items = cat.items
        .map((it) => {
          const name = lang === 'ru' ? it.ru : it.kk;
          const meta = lang === 'ru' ? it.metaRu : it.metaKk;
          return { name, meta };
        })
        .filter((it) => it.name.toLowerCase().includes(q) || it.meta.toLowerCase().includes(q));

      if (q && items.length === 0) return '';

      const itemsHtml = items
        .map(
          (it) => `
        <div class="course-item">
          <div class="course-row">
            <div class="course-title">${escapeHtml(it.name)}</div>
            <div class="course-actions">
              <button class="course-btn" onclick="openOrdersTab()">${escapeHtml(t('messages'))}</button>
              <button class="course-btn primary" onclick="openOrderCreate('${escapeJs(it.name)}')">${escapeHtml(lang === 'ru' ? 'Заказать' : 'Тапсырыс')}</button>
            </div>
          </div>
          <div class="course-meta">${escapeHtml(it.meta)}</div>
        </div>
      `
        )
        .join('');

      return `
        <div class="course-accordion ${idx === 0 && !q ? 'open' : ''}">
          <div class="acc-head" onclick="toggleAccordion(this)">
            <div class="left">
              <div class="course-title">${escapeHtml(title)}</div>
              <div class="course-meta">${escapeHtml(subtitle)}</div>
            </div>
            <div class="right">
              <svg class="chev" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <polyline points="6 9 12 15 18 9"></polyline>
              </svg>
            </div>
          </div>
          <div class="acc-body">${itemsHtml}</div>
        </div>
      `;
    }).join('');

    root.innerHTML = blocks || `<div class="txt-sm">${escapeHtml(t('nothingFound'))}</div>`;
  }

  // =============================
  // Profile stats/recent
  // =============================
  function applyProfileStatsFromServer() {
    const data = window.__PROFILE_DATA;
    if (!data || !data.stats) return;

    const orders = Number(data.stats.orders ?? 0);
    const bonus = Number(data.stats.bonus ?? 0);
    const ratingCnt = Number(data.stats.rating_count ?? 0);
    const ratingAvg = data.stats.rating_avg;

    const pProgress = qs('#pProgress');
    const pAccuracy = qs('#pAccuracy');
    const pStreak = qs('#pStreak');

    if (pProgress) pProgress.textContent = String(orders);
    if (pStreak) pStreak.textContent = `${formatMoney(bonus)}тг`;

    if (pAccuracy) {
      if (ratingCnt > 0 && ratingAvg !== null && ratingAvg !== undefined && !Number.isNaN(Number(ratingAvg))) {
        pAccuracy.textContent = Number(ratingAvg).toFixed(1);
      } else {
        pAccuracy.textContent = '—';
      }
    }
  }

  function renderProfileRecent() {
    const wrap = qs('#profileCourses');
    if (!wrap) return;
    const lang = getLang();

    const data = window.__PROFILE_DATA;
    const role = data?.role || null;
    const recent = Array.isArray(data?.recent_orders) ? data.recent_orders : null;

    const whoLabel = role === 'master' ? (lang === 'ru' ? 'Клиент' : 'Тапсырыс беруші') : (lang === 'ru' ? 'Мастер' : 'Шебер');

    const statusMap = {
      kk: { new: t('statusNew'), in_progress: t('statusInProgress'), completed: t('statusCompleted'), cancelled: t('statusCancelled') },
      ru: { new: t('statusNew'), in_progress: t('statusInProgress'), completed: t('statusCompleted'), cancelled: t('statusCancelled') },
    };

    if (!recent) {
      wrap.innerHTML = `<div class="txt-sm" style="opacity:.75; text-align:center; padding:14px 4px;">${escapeHtml(lang === 'ru' ? 'Пока нет заказов' : 'Әзірге тапсырыс жоқ')}</div>`;
      return;
    }

    if (recent.length === 0) {
      wrap.innerHTML = `<div class="txt-sm" style="opacity:.75; text-align:center; padding:14px 4px;">${escapeHtml(t('noOrdersYet'))}</div>`;
      return;
    }

    wrap.innerHTML = recent
      .map((o) => {
        const title = o?.service_title || (lang === 'ru' ? 'Услуга' : 'Қызмет');
        const price = Number(o?.price ?? 0);
        const status = String(o?.status || 'new');
        const oid = Number(o?.id ?? 0);
        const other = o?.other_name ? String(o.other_name) : '';
        const dt = o?.completed_at || o?.created_at || '';
        const dtLabel = dt ? formatShortDate(dt) : '';

        const stLabel = statusMap[lang]?.[status] || status;
        const badge = status === 'completed' ? 'OK' : status === 'in_progress' ? 'IN' : status === 'cancelled' ? 'X' : 'NEW';

        const metaParts = [
          `${stLabel} • ${formatMoney(price)} ₸`,
          other ? `${whoLabel}: ${other}` : '',
          dtLabel ? dtLabel : '',
        ].filter(Boolean);

        return `
        <div class="list-item" ${oid > 0 ? `onclick="openOrderChat(${oid})"` : ''}>
          <div style="display:flex; flex-direction:column; gap:4px;">
            <div class="h3">${escapeHtml(title)}</div>
            <div class="txt-sm">${escapeHtml(metaParts.join(' • '))}</div>
          </div>
          <div class="deadline st-${escapeHtml(status)}">${escapeHtml(badge)}</div>
        </div>
      `;
      })
      .join('');
  }

  // =============================
  // Orders + chat
  // =============================
  const ORDERS_STATE = {
    currentOrderId: 0,
    currentOrder: null,
    lastMsgId: 0,
    pollTimer: null,
  };

  // CSRF (session-based)
  let CSRF_TOKEN = '';
  async function ensureCsrf() {
    if (CSRF_TOKEN) return CSRF_TOKEN;
    try {
      const res = await fetch('api/csrf.php', { credentials: 'same-origin' });
      const j = await res.json();
      if (res.ok && j?.ok && j?.data?.csrf_token) CSRF_TOKEN = String(j.data.csrf_token);
    } catch { }
    return CSRF_TOKEN;
  }

  async function apiGet(url) {
    const res = await fetch(url, { credentials: 'same-origin' });
    let data = null;
    try {
      data = await res.json();
    } catch { }
    if (!res.ok || !data || data.ok === false) {
      const err = data?.error ? data.error : 'http_' + res.status;
      throw new Error(err);
    }
    return data.data;
  }

  async function apiPost(url, bodyObj) {
    await ensureCsrf();
    const params = new URLSearchParams();
    Object.entries(bodyObj || {}).forEach(([k, v]) => params.append(k, String(v ?? '')));

    const res = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
        'X-CSRF-Token': CSRF_TOKEN,
      },
      body: params,
      credentials: 'same-origin',
    });

    let data = null;
    try {
      data = await res.json();
    } catch { }
    if (!res.ok || !data || data.ok === false) {
      const err = data?.error ? data.error : 'http_' + res.status;
      throw new Error(err);
    }
    return data.data;
  }

  // =============================
  // MASTER SEARCH (client fast flow)
  // =============================
  let masterSearchState = {
    city: '',
    masters: [],
    loaded: false,
    lastError: '',
  };

  function normalizePhoneDigits(phone) {
    let digits = String(phone || '').replace(/\D+/g, '');
    if (!digits) return '';
    if (digits.length === 11 && digits.startsWith('8')) digits = '7' + digits.slice(1);
    if (digits.length === 10) digits = '7' + digits;
    return digits;
  }

  function renderMasterSearchResults() {
    const cityEl = qs('#mastersSearchSelectedCity');
    const countEl = qs('#mastersSearchCount');
    const listEl = qs('#mastersList');
    if (!cityEl || !countEl || !listEl) return;

    const city = String(masterSearchState.city || '').trim();
    const masters = Array.isArray(masterSearchState.masters) ? masterSearchState.masters : [];

    cityEl.textContent = city || (getLang() === 'ru' ? 'Не выбран' : 'Таңдалмаған');

    if (!city) {
      countEl.textContent = getLang() === 'ru' ? 'Выберите город для поиска' : 'Іздеу үшін қаланы таңдаңыз';
      listEl.innerHTML = `
        <div class="card" style="padding:24px;text-align:center;">
          <div style="font-size:40px;margin-bottom:12px;">🔍</div>
          <div class="h2" style="margin-bottom:8px;">${escapeHtml(t('mastersPromptTitle'))}</div>
          <div class="txt-sm" style="opacity:.7;margin-bottom:16px;">${escapeHtml(t('mastersPromptDesc'))}</div>
          <button class="cta-btn" onclick="primaryAction()" style="margin:0 auto;font-size:15px;padding:13px 24px;">
            ${escapeHtml(getLang() === 'ru' ? 'Выбрать город' : 'Қаланы таңдау')}
          </button>
        </div>`;
      return;
    }

    if (masterSearchState.lastError) {
      countEl.textContent = tr('mastersCountFound', { count: 0 });
      listEl.innerHTML = `
        <div class="card" style="padding:18px;text-align:center;">
          <div class="h2" style="margin-bottom:6px;">${escapeHtml(t('mastersSearchError'))}</div>
          <div class="txt-sm" style="opacity:.7;">${escapeHtml(masterSearchState.lastError)}</div>
        </div>`;
      return;
    }

    countEl.textContent = tr('mastersCountFoundInCity', { city, count: masters.length });

    if (!masters.length) {
      listEl.innerHTML = `
        <div class="card" style="padding:18px;text-align:center;">
          <div class="h2" style="margin-bottom:6px;">${escapeHtml(t('mastersEmptyTitle'))}</div>
          <div class="txt-sm" style="opacity:.7;">${escapeHtml(t('mastersEmptyDesc'))}</div>
        </div>`;
      return;
    }

    listEl.innerHTML = masters.map((m, idx) => {
      const lang = getLang();
      const name = String(m?.name || (lang === 'ru' ? 'Мастер' : 'Шебер'));
      const profession = String(m?.profession || '');
      const phone = String(m?.phone || '');
      const cityName = String(m?.city || city || '');
      const experience = Number(m?.experience || 0);
      const ratingAvg = m?.rating_avg === null || typeof m?.rating_avg === 'undefined' ? null : Number(m.rating_avg);
      const ratingCount = Number(m?.rating_count || 0);
      const avatarUrl = String(m?.avatar_url || '');
      const avatarColor = String(m?.avatar_color || '#1cb7ff');
      const isOnline = Number(m?.is_online || 0) === 1;
      const initial = name.trim().charAt(0).toUpperCase() || 'M';
      const phoneDigits = normalizePhoneDigits(phone);
      const telHref = phoneDigits ? `tel:${phoneDigits}` : '';
      const waHref = phoneDigits ? `https://wa.me/${phoneDigits}?text=${encodeURIComponent(lang === 'ru' ? 'Здравствуйте! Нашёл вас на Sheber.kz' : 'Сәлем! Sheber.kz сайтынан таптым')}` : '';
      const avatarHtml = avatarUrl
        ? `<div style="width:54px;height:54px;border-radius:50%;flex-shrink:0;background:url('${escapeHtml(avatarUrl)}') center/cover;"></div>`
        : `<div style="width:54px;height:54px;border-radius:50%;flex-shrink:0;background:${escapeHtml(avatarColor)};display:flex;align-items:center;justify-content:center;font-weight:800;color:#fff;font-size:20px;">${escapeHtml(initial)}</div>`;
      const ratingText = ratingAvg !== null
        ? ` ${ratingAvg.toFixed(1)}${ratingCount > 0 ? ` (${ratingCount})` : ''}`
        : ' —';
      const expText = experience > 0 ? `${experience} ${t('yearsSuffix')}` : '—';
      const onlineDot = isOnline ? `<span style="width:10px;height:10px;border-radius:50%;background:#2ec4b6;display:inline-block;margin-left:6px;vertical-align:middle;"></span>` : '';

      return `
        <div class="card" style="padding:14px 16px;margin-bottom:10px;cursor:pointer;" onclick="openMasterProfile(${idx})">
          <div style="display:flex;gap:12px;align-items:center;margin-bottom:12px;">
            ${avatarHtml}
            <div style="flex:1;min-width:0;">
              <div style="font-weight:800;font-size:15px;line-height:1.25;word-break:break-word;">${escapeHtml(name)}${onlineDot}</div>
              ${profession ? `<div style="font-size:12px;color:var(--primary);font-weight:700;margin-top:2px;">${escapeHtml(profession)}</div>` : ''}
              <div class="txt-sm" style="opacity:.6;margin-top:2px;font-size:12px;">${escapeHtml(cityName || city)} &nbsp;•&nbsp; ${escapeHtml(ratingText)} &nbsp;•&nbsp; ${escapeHtml(expText)}</div>
            </div>
            <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="var(--text-sec)" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="flex-shrink:0;opacity:.5;"><polyline points="9 18 15 12 9 6"/></svg>
          </div>
          <div style="display:flex;gap:8px;" onclick="event.stopPropagation()">
            ${telHref ? `<a href="${telHref}" style="flex:1;display:inline-flex;align-items:center;justify-content:center;gap:7px;padding:12px;border-radius:12px;background:var(--primary);color:#fff;font-weight:800;font-size:14px;text-decoration:none;"><svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07A19.5 19.5 0 0 1 4.69 12 19.79 19.79 0 0 1 1.61 3.44 2 2 0 0 1 3.6 2h3a2 2 0 0 1 2 1.72c.127.96.361 1.903.7 2.81a2 2 0 0 1-.45 2.11L7.91 9.91a16 16 0 0 0 6.1 6.1l.97-.97a2 2 0 0 1 2.11-.45c.907.339 1.85.573 2.81.7A2 2 0 0 1 21.72 17.18z"/></svg>${escapeHtml(t('mastersCallBtn'))}</a>` : ''}
            ${waHref ? `<a href="${waHref}" target="_blank" rel="noopener" style="flex:1;display:inline-flex;align-items:center;justify-content:center;gap:7px;padding:12px;border-radius:12px;background:#25D366;color:#fff;font-weight:800;font-size:14px;text-decoration:none;"><svg viewBox="0 0 24 24" width="16" height="16" fill="currentColor"><path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347z"/><path d="M11.5 2.5C6.261 2.5 2 6.761 2 12.001c0 1.71.447 3.315 1.228 4.71L2 22l5.442-1.426A9.46 9.46 0 0 0 11.5 21.5c5.238 0 9.5-4.261 9.5-9.5 0-5.238-4.262-9.5-9.5-9.5zm0 17.25a7.729 7.729 0 0 1-3.948-1.084l-.283-.168-2.932.769.783-2.859-.184-.293A7.717 7.717 0 0 1 3.75 12c0-4.274 3.476-7.75 7.75-7.75s7.75 3.476 7.75 7.75-3.476 7.75-7.75 7.75z"/></svg>${escapeHtml(t('mastersWhatsAppBtn'))}</a>` : ''}
            ${!telHref && !waHref ? `<div style="padding:12px;border-radius:12px;background:var(--surface-highlight);color:var(--text-sec);font-size:13px;width:100%;text-align:center;">${escapeHtml(t('mastersPhoneMissing'))}</div>` : ''}
          </div>
        </div>`;
    }).join('');
  }

  function openCreateOrder() {
    const u = getLocalUser();
    const modal = qs('#createOrderModal');
    const overlay = qs('#createOrderOverlay');
    if (!modal || !overlay) return;

    const city = qs('#orderCity');
    if (city) city.value = masterSearchState.city || u?.city || '';

    modal.classList.add('active');
    overlay.classList.add('active');
  }

  function closeCreateOrder() {
    const modal = qs('#createOrderModal');
    const overlay = qs('#createOrderOverlay');
    if (modal) modal.classList.remove('active');
    if (overlay) overlay.classList.remove('active');
  }

  // =============================
  // MASTER PROFILE MODAL
  // =============================
  let _currentMasterData = null;

  function openMasterProfile(masterIdx) {
    const masters = masterSearchState.masters;
    const m = (typeof masterIdx === 'number') ? masters[masterIdx] : masterIdx;
    if (!m) return;
    _currentMasterData = m;

    const modal = qs('#masterProfileModal');
    const overlay = qs('#masterProfileOverlay');
    const body = qs('#masterProfileBody');
    if (!modal || !body) return;

    const lang = getLang();
    const name = String(m?.name || (lang === 'ru' ? 'Мастер' : 'Шебер'));
    const profession = String(m?.profession || '');
    const bio = String(m?.bio || '');
    const phone = String(m?.phone || '');
    const cityName = String(m?.city || '');
    const experience = Number(m?.experience || 0);
    const ratingAvg = (m?.rating_avg === null || m?.rating_avg === undefined) ? null : Number(m.rating_avg);
    const ratingCount = Number(m?.rating_count || 0);
    const avatarUrl = String(m?.avatar_url || '');
    const avatarColor = String(m?.avatar_color || '#1cb7ff');
    const isOnline = Number(m?.is_online || 0) === 1;
    const initial = name.trim().charAt(0).toUpperCase() || 'M';
    const phoneDigits = normalizePhoneDigits(phone);
    const telHref = phoneDigits ? `tel:${phoneDigits}` : '';
    const waHref = phoneDigits ? `https://wa.me/${phoneDigits}?text=${encodeURIComponent(lang === 'ru' ? 'Здравствуйте! Нашёл вас на Sheber.kz' : 'Сәлем! Sheber.kz сайтынан таптым')}` : '';
    const ratingText = ratingAvg !== null ? `${ratingAvg.toFixed(1)} ★ (${ratingCount})` : '—';
    const expText = experience > 0 ? `${experience} ${t('yearsSuffix')}` : '—';

    const avatarHtml = avatarUrl
      ? `<div style="width:80px;height:80px;border-radius:50%;background:url('${escapeHtml(avatarUrl)}') center/cover;flex-shrink:0;"></div>`
      : `<div style="width:80px;height:80px;border-radius:50%;background:${escapeHtml(avatarColor)};display:flex;align-items:center;justify-content:center;font-weight:800;color:#fff;font-size:28px;flex-shrink:0;">${escapeHtml(initial)}</div>`;

    body.innerHTML = `
      <div style="display:flex;flex-direction:column;gap:16px;">
        <!-- Avatar + Name -->
        <div style="display:flex;align-items:center;gap:16px;">
          ${avatarHtml}
          <div style="flex:1;min-width:0;">
            <div style="font-weight:900;font-size:20px;line-height:1.2;margin-bottom:3px;">${escapeHtml(name)}</div>
            ${profession ? `<div style="font-size:14px;color:var(--primary);font-weight:700;margin-bottom:3px;">${escapeHtml(profession)}</div>` : ''}
            ${isOnline ? `<span style="display:inline-flex;align-items:center;gap:5px;padding:3px 10px;border-radius:999px;background:rgba(46,196,182,.12);color:#2ec4b6;font-size:11px;font-weight:700;">● ${lang === 'ru' ? 'Онлайн' : 'Онлайн'}</span>` : ''}
          </div>
        </div>

        <!-- Stats grid -->
        <div style="display:grid;grid-template-columns:repeat(2,1fr);gap:10px;">
          <div style="padding:14px;border-radius:14px;background:var(--surface-highlight);border:1px solid var(--border);text-align:center;">
            <div class="txt-sm" style="opacity:.6;margin-bottom:4px;">${escapeHtml(t('masterAvgRating'))}</div>
            <div style="font-size:20px;font-weight:900;"> ${escapeHtml(ratingText)}</div>
          </div>
          <div style="padding:14px;border-radius:14px;background:var(--surface-highlight);border:1px solid var(--border);text-align:center;">
            <div class="txt-sm" style="opacity:.6;margin-bottom:4px;">${escapeHtml(t('masterExperience'))}</div>
            <div style="font-size:20px;font-weight:900;">${escapeHtml(expText)}</div>
          </div>
        </div>

        <!-- City -->
        ${cityName ? `<div style="display:flex;align-items:center;gap:10px;padding:12px 14px;background:var(--surface-highlight);border:1px solid var(--border);border-radius:14px;">
          <svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="var(--primary)" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7z"/><circle cx="12" cy="9" r="2.5"/></svg>
          <div>
            <div class="txt-sm" style="opacity:.6;">${escapeHtml(t('masterCity'))}</div>
            <div style="font-weight:700;">${escapeHtml(cityName)}</div>
          </div>
        </div>` : ''}

        <!-- Bio -->
        ${bio ? `<div style="padding:14px;background:var(--surface-highlight);border:1px solid var(--border);border-radius:14px;">
          <div class="txt-sm" style="opacity:.6;margin-bottom:6px;font-weight:700;">${escapeHtml(t('masterAbout'))}</div>
          <div style="font-size:14px;line-height:1.6;">${escapeHtml(bio)}</div>
        </div>` : ''}

        <!-- Contacts -->
        <div style="padding:14px;background:var(--surface-highlight);border:1px solid var(--border);border-radius:14px;">
          <div class="txt-sm" style="opacity:.6;margin-bottom:8px;font-weight:700;">${escapeHtml(t('masterContacts'))}</div>
          ${phone ? `<div style="font-weight:700;font-size:16px;margin-bottom:10px;">${escapeHtml(phone)}</div>` : `<div style="opacity:.6;font-size:13px;margin-bottom:10px;">${escapeHtml(t('masterNoPhone'))}</div>`}
          <div style="display:flex;gap:10px;flex-wrap:wrap;">
            ${telHref ? `<a href="${telHref}" style="flex:1;min-width:130px;display:inline-flex;align-items:center;justify-content:center;gap:8px;padding:14px 16px;border-radius:14px;background:var(--primary);color:#fff;font-weight:800;font-size:15px;text-decoration:none;">
              <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07A19.5 19.5 0 0 1 4.69 12 19.79 19.79 0 0 1 1.61 3.44 2 2 0 0 1 3.6 2h3a2 2 0 0 1 2 1.72c.127.96.361 1.903.7 2.81a2 2 0 0 1-.45 2.11L7.91 9.91a16 16 0 0 0 6.1 6.1l.97-.97a2 2 0 0 1 2.11-.45c.907.339 1.85.573 2.81.7A2 2 0 0 1 21.72 17.18z"/></svg>
              ${escapeHtml(t('masterCallBtn'))}
            </a>` : ''}
            ${waHref ? `<a href="${waHref}" target="_blank" rel="noopener" style="flex:1;min-width:130px;display:inline-flex;align-items:center;justify-content:center;gap:8px;padding:14px 16px;border-radius:14px;background:#25D366;color:#fff;font-weight:800;font-size:15px;text-decoration:none;">
              <svg viewBox="0 0 24 24" width="18" height="18" fill="currentColor"><path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347z"/><path d="M11.5 2.5C6.261 2.5 2 6.761 2 12.001c0 1.71.447 3.315 1.228 4.71L2 22l5.442-1.426A9.46 9.46 0 0 0 11.5 21.5c5.238 0 9.5-4.261 9.5-9.5 0-5.238-4.262-9.5-9.5-9.5zm0 17.25a7.729 7.729 0 0 1-3.948-1.084l-.283-.168-2.932.769.783-2.859-.184-.293A7.717 7.717 0 0 1 3.75 12c0-4.274 3.476-7.75 7.75-7.75s7.75 3.476 7.75 7.75-3.476 7.75-7.75 7.75z"/></svg>
              ${escapeHtml(t('masterWaBtn'))}
            </a>` : ''}
          </div>
        </div>
      </div>
    `;

    modal.classList.add('active');
    // оверлей не активируем — блюр фона не нужен для профиля мастера
  }

  function closeMasterProfile() {
    const modal = qs('#masterProfileModal');
    const overlay = qs('#masterProfileOverlay');
    if (modal) modal.classList.remove('active');
    if (overlay) overlay.classList.remove('active');
  }

  async function submitOrder() {
    const city = String(qs('#orderCity')?.value || '').trim();
    if (!city) {
      showToast(t('mastersChooseCityToast'));
      return;
    }

    masterSearchState.city = city;
    masterSearchState.masters = [];
    masterSearchState.loaded = false;
    masterSearchState.lastError = '';

    setTab('courses');
    const countEl = qs('#mastersSearchCount');
    const listEl = qs('#mastersList');
    const cityEl = qs('#mastersSearchSelectedCity');
    if (cityEl) cityEl.textContent = city;
    if (countEl) countEl.textContent = t('mastersLoading');
    if (listEl) listEl.innerHTML = `<div class="card" style="padding:18px;text-align:center;">${escapeHtml(t('mastersLoading'))}</div>`;

    try {
      const masters = await apiGet('api/masters_list.php?city=' + encodeURIComponent(city));
      masterSearchState.masters = Array.isArray(masters) ? masters : [];
      masterSearchState.loaded = true;
      masterSearchState.lastError = '';
      closeCreateOrder();
      renderMasterSearchResults();
    } catch (e) {
      masterSearchState.loaded = true;
      masterSearchState.lastError = t('mastersSearchError');
      renderMasterSearchResults();
      showToast(t('mastersSearchError'));
    }
  }

  async function renderMyOrders() {

    const container = qs('#myOrdersList');
    if (!container) return;

    const u = getLocalUser();
    if (!u) {
      // guest
      container.innerHTML = `
        <div class="empty-state">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
            <rect x="3" y="3" width="18" height="18" rx="2"></rect>
            <line x1="9" y1="9" x2="15" y2="9"></line>
            <line x1="9" y1="13" x2="12" y2="13"></line>
          </svg>
          <div class="empty-title">${escapeHtml(getLang() === 'ru' ? 'Войдите, чтобы видеть заказы' : 'Тапсырыстарды көру үшін кіріңіз')}</div>
          <div class="empty-desc">${escapeHtml(getLang() === 'ru' ? 'После входа вы сможете создавать заказы' : 'Кіргеннен кейін тапсырыс жасай аласыз')}</div>
        </div>`;
      return;
    }

    try {
      const orders = await apiGet('api/orders_list.php?limit=20');
      if (!Array.isArray(orders) || orders.length === 0) {
        container.innerHTML = `
          <div class="empty-state">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
              <rect x="3" y="3" width="18" height="18" rx="2"></rect>
              <line x1="9" y1="9" x2="15" y2="9"></line>
              <line x1="9" y1="13" x2="12" y2="13"></line>
            </svg>
            <div class="empty-title">${escapeHtml(getLang() === 'ru' ? 'Нет заказов' : 'Тапсырыстар жоқ')}</div>
            <div class="empty-desc">${escapeHtml(getLang() === 'ru' ? 'Нажмите «+», чтобы создать заказ' : '«+» батырмасын басып тапсырыс жасаңыз')}</div>
          </div>`;
        return;
      }

      container.innerHTML = orders
        .filter(o => Number(o?.client_id || 0) === Number(u.id || 0)) // home shows client orders
        .slice(0, 10)
        .map((o) => {
          const title = String(o?.service_title || (getLang() === 'ru' ? 'Заказ' : 'Тапсырыс'));
          const desc = String(o?.description || '');
          const addr = String(o?.address || '');
          const price = Number(o?.price || 0);
          const created = String(o?.created_at || '');
          const dt = created ? formatShortDate(created) : '';
          const photos = Array.isArray(o?.photos) ? o.photos : [];

          const photoHtml = photos.length
            ? `<div style="display:flex; gap:6px; margin-top:8px; overflow-x:auto;">` +
              photos.slice(0, 3).map((p) => `<img src="${escapeHtml(p)}" style="width:48px;height:48px;border-radius:8px;object-fit:cover;">`).join('') +
              `</div>`
            : '';

          return `
            <div class="card" style="padding:16px; margin-bottom:10px; border-radius:14px; cursor:pointer;" onclick="openOrderChat(${Number(o.id)})">
              <div style="display:flex; justify-content:space-between; margin-bottom:6px;">
                <div class="h3" style="font-size:14px;">${escapeHtml(title)}</div>
                <div style="font-size:12px; color:var(--text-sec);">${escapeHtml(dt)}</div>
              </div>
              <div class="txt-sm" style="margin-bottom:6px;">${escapeHtml(desc)}</div>
              <div style="display:flex; justify-content:space-between; align-items:center; gap:10px;">
                <div class="txt-sm" style="min-width:0; overflow:hidden; text-overflow:ellipsis; white-space:nowrap;">${escapeHtml(addr)}</div>
                ${price ? `<div style="font-weight:700; color:var(--text-main); white-space:nowrap;">${escapeHtml(formatMoney(price))} ₸</div>` : ''}
              </div>
              ${photoHtml}
            </div>
          `;
        })
        .join('');
    } catch (e) {
      container.innerHTML = `
        <div class="empty-state">
          <div class="empty-title">${escapeHtml(getLang() === 'ru' ? 'Ошибка загрузки заказов' : 'Тапсырыстар жүктелмеді')}</div>
        </div>`;
    }
  }

function openOrdersTab() {
    setTab('messages');
  }

  // =============================
  // ORDERS TABS (Актуальные / Завершённые)
  // =============================
  let _ordersCache = null;
  let _currentOrderTab = 'actual';

  async function switchOrderTab(tab) {
    _currentOrderTab = tab;

    // update button styles
    const btnActual = qs('#tabActual');
    const btnCompleted = qs('#tabCompleted');
    if (btnActual) btnActual.classList.toggle('active', tab === 'actual');
    if (btnCompleted) btnCompleted.classList.toggle('active', tab === 'completed');

    // load if not cached
    if (!_ordersCache) {
      const container = qs('#ordersContainer');
      if (container) container.innerHTML = `<div class="txt-sm" style="opacity:.75; text-align:center; padding:14px 4px;">${getLang() === 'ru' ? 'Загрузка...' : 'Жүктелуде...'}</div>`;
      try {
        _ordersCache = await apiGet('api/orders_list.php?limit=50');
      } catch (e) {
        if (container) container.innerHTML = `<div class="txt-sm" style="opacity:.8; text-align:center; padding:14px 4px;">${getLang() === 'ru' ? 'Ошибка загрузки' : 'Жүктелмеді'}</div>`;
        return;
      }
    }

    renderOrdersContainer(_ordersCache, tab);
  }

  function renderOrdersContainer(orders, tab) {
    const container = qs('#ordersContainer');
    if (!container) return;
    const u = getLocalUser();
    const lang = getLang();

    if (!Array.isArray(orders) || orders.length === 0) {
      container.innerHTML = `<div class="txt-sm" style="opacity:.75; text-align:center; padding:24px 4px;">${lang === 'ru' ? 'Заказов пока нет' : 'Тапсырыстар әзірге жоқ'}</div>`;
      return;
    }

    // filter by tab
    const activeStatuses = ['new', 'in_progress'];
    const doneStatuses = ['completed', 'cancelled'];
    const filtered = orders.filter(o => {
      const st = String(o?.status || 'new');
      return tab === 'actual' ? activeStatuses.includes(st) : doneStatuses.includes(st);
    });

    if (filtered.length === 0) {
      const msg = tab === 'actual'
        ? (lang === 'ru' ? 'Нет активных заказов' : 'Белсенді тапсырыстар жоқ')
        : (lang === 'ru' ? 'Нет завершённых заказов' : 'Аяқталған тапсырыстар жоқ');
      container.innerHTML = `<div class="txt-sm" style="opacity:.75; text-align:center; padding:24px 4px;">${msg}</div>`;
      return;
    }

    const statusLabel = { new: lang === 'ru' ? 'Новый' : 'Жаңа', in_progress: lang === 'ru' ? 'В процессе' : 'Жұмыста', completed: lang === 'ru' ? 'Завершён' : 'Аяқталды', cancelled: lang === 'ru' ? 'Отменён' : 'Бас тартылды' };
    const statusColor = { new: 'var(--primary)', in_progress: '#f0a500', completed: '#2ec4b6', cancelled: '#ff5a5f' };

    container.innerHTML = filtered.map(o => {
      const oid = Number(o?.id ?? 0);
      const title = String(o?.service_title || o?.description || (lang === 'ru' ? 'Заказ' : 'Тапсырыс')).slice(0, 60);
      const desc = String(o?.description || '').slice(0, 100);
      const price = Number(o?.price || 0);
      const st = String(o?.status || 'new');
      const stLabel = statusLabel[st] || st;
      const stColor = statusColor[st] || 'var(--text-sec)';
      const time = o?.updated_at || o?.created_at || '';
      const timeLabel = time ? formatShortDate(time) : '';

      const otherName = u?.role === 'master'
        ? String(o?.client_name || (lang === 'ru' ? 'Клиент' : 'Клиент'))
        : String(o?.master_name || (lang === 'ru' ? 'Мастер ищется...' : 'Шебер іздеуде...'));

      const avatarColor = u?.role === 'master'
        ? String(o?.client_avatar_color || '#1cb7ff')
        : String(o?.master_avatar_color || '#1cb7ff');
      const avatarUrl = u?.role === 'master'
        ? String(o?.client_avatar_url || '')
        : String(o?.master_avatar_url || '');
      const initial = otherName.trim().charAt(0).toUpperCase() || '?';

      const avatarHtml = avatarUrl
        ? `<div style="width:44px;height:44px;border-radius:50%;flex-shrink:0;background:url('${escapeHtml(avatarUrl)}') center/cover;"></div>`
        : `<div style="width:44px;height:44px;border-radius:50%;flex-shrink:0;background:${escapeHtml(avatarColor)};display:flex;align-items:center;justify-content:center;font-weight:700;color:#fff;font-size:16px;">${escapeHtml(initial)}</div>`;

      return `
        <div class="card" style="padding:16px;margin-bottom:10px;border-radius:14px;cursor:pointer;" onclick="openOrderChat(${oid})">
          <div style="display:flex;gap:12px;align-items:center;">
            ${avatarHtml}
            <div style="flex:1;min-width:0;">
              <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:4px;">
                <div style="font-weight:700;font-size:14px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;">${escapeHtml(otherName)}</div>
                <div style="font-size:11px;color:var(--text-sec);flex-shrink:0;margin-left:8px;">${escapeHtml(timeLabel)}</div>
              </div>
              <div style="font-size:13px;font-weight:600;margin-bottom:4px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;">${escapeHtml(title)}</div>
              <div style="display:flex;justify-content:space-between;align-items:center;">
                ${price ? `<div style="font-weight:700;color:var(--primary);font-size:13px;">${escapeHtml(formatMoney(price))} ₸</div>` : '<div></div>'}
                <span style="font-size:11px;font-weight:600;color:${stColor};padding:3px 8px;border-radius:999px;border:1px solid ${stColor};opacity:.9;">${escapeHtml(stLabel)}</span>
              </div>
            </div>
          </div>
        </div>`;
    }).join('');
  }

  async function loadOrdersList() {
    const root = qs('#ordersList');
    if (!root) return;

    const u = getLocalUser();
    const lang = getLang();

    if (!u) {
      root.innerHTML = `
        <div class="card">
          <div class="h2" style="margin-bottom:6px;">${escapeHtml(t('ordersLoginTitle'))}</div>
          <div class="txt-sm" style="margin-bottom:12px;">${escapeHtml(t('ordersLoginDesc'))}</div>
          <button class="cta-btn" type="button" onclick="setTab('profile')">${escapeHtml(t('orderOpenProfile'))}</button>
        </div>
      `;
      return;
    }

    root.innerHTML = `<div class="txt-sm" style="opacity:.75; text-align:center; padding:14px 4px;">${escapeHtml(t('ordersLoading'))}</div>`;

    try {
      const orders = await apiGet('api/orders_list.php');
      if (!Array.isArray(orders) || orders.length === 0) {
        root.innerHTML = `<div class="txt-sm" style="opacity:.75; text-align:center; padding:14px 4px;">${escapeHtml(t('noOrdersYet'))}</div>`;
        return;
      }

      const statusMap = {
        kk: { new: t('statusNew'), in_progress: t('statusInProgress'), completed: t('statusCompleted'), cancelled: t('statusCancelled') },
        ru: { new: t('statusNew'), in_progress: t('statusInProgress'), completed: t('statusCompleted'), cancelled: t('statusCancelled') },
      };

      root.innerHTML = orders
        .map((o) => {
          const oid = Number(o?.id ?? 0);
          const title = o?.service_title || (lang === 'ru' ? 'Услуга' : 'Қызмет');
          const st = String(o?.status || 'new');
          const stLabel = statusMap[lang]?.[st] || st;

          const otherName =
            u.role === 'master'
              ? o?.client_name || (lang === 'ru' ? 'Клиент' : 'Клиент')
              : o?.master_name || (lang === 'ru' ? 'Мастер' : 'Шебер');

          const otherAvatarUrl = u.role === 'master' ? String(o?.client_avatar_url || '') : String(o?.master_avatar_url || '');
          const otherAvatarColor = u.role === 'master' ? String(o?.client_avatar_color || '') : String(o?.master_avatar_color || '');
          const last = o?.last_message || o?.description || '';
          const time = o?.last_message_at || o?.updated_at || o?.created_at || '';
          const timeLabel = time ? formatShortDate(time) : '';

          const avatarStyle = otherAvatarUrl
            ? `background-image:url('${escapeHtml(otherAvatarUrl)}'); background-size:cover; background-position:center; background-color:${escapeHtml(otherAvatarColor || 'var(--surface-highlight)')};`
            : `background-image:url('https://api.dicebear.com/7.x/identicon/svg?seed=${encodeURIComponent(otherName)}'); background-color:${escapeHtml(otherAvatarColor || 'var(--surface-highlight)')};`;

          return `
          <div class="msg-item" onclick="openOrderChat(${oid})">
            <div class="msg-av" style="${avatarStyle}"></div>
            <div class="msg-content">
              <div class="msg-top">
                <div class="msg-name">${escapeHtml(otherName)}</div>
                <div class="msg-time">${escapeHtml(timeLabel)}</div>
              </div>
              <div class="msg-text">${escapeHtml(title)} • ${escapeHtml(stLabel)}${last ? ' — ' + escapeHtml(last) : ''}</div>
            </div>
          </div>
        `;
        })
        .join('');
    } catch (e) {
      root.innerHTML = `<div class="txt-sm" style="opacity:.8; text-align:center; padding:14px 4px;">${escapeHtml(
        lang === 'ru' ? 'Ошибка загрузки заказов' : 'Тапсырыстар жүктелмеді'
      )}</div>`;
    }
  }

  async function openOrderCreate(serviceTitle) {
    // unified create-order UI (home.html style)
    openCreateOrder(serviceTitle);
  }

  function toggleOrderCreate() {
    // backward compatibility
    const modal = qs('#createOrderModal');
    const overlay = qs('#createOrderOverlay');
    if (!modal || !overlay) return;
    const willOpen = !modal.classList.contains('active');
    if (willOpen) openCreateOrder();
    else closeCreateOrder();
  }


  // Detect client location via GPS (browser geolocation)
  function ocDetectLocation(btn) {
    const latEl = qs('#ocLat');
    const lngEl = qs('#ocLng');
    const addrEl = qs('#orderAddress');

    if (!navigator.geolocation) {
      showToast(getLang() === 'ru' ? 'Геолокация не поддерживается' : 'Геолокация қолжетімсіз');
      return;
    }

    const oldHtml = btn ? btn.innerHTML : '';
    if (btn) {
      btn.disabled = true;
      btn.style.opacity = '0.85';
      btn.innerHTML = (getLang() === 'ru' ? 'Определяю...' : 'Анықтап жатырмын...');
    }

    navigator.geolocation.getCurrentPosition(
      (pos) => {
        const lat = pos.coords.latitude;
        const lng = pos.coords.longitude;

        if (latEl) latEl.value = String(lat);
        if (lngEl) lngEl.value = String(lng);

        // ВАЖНО: в поле адреса вставляем ТОЛЬКО координаты (без "GPS:")
        // (делаем это только если поле адреса пустое)
        if (addrEl && !String(addrEl.value || '').trim()) {
          addrEl.value = `${lat.toFixed(5)}, ${lng.toFixed(5)}`; // или без пробела: `${lat.toFixed(5)},${lng.toFixed(5)}`
        }

        showToast(getLang() === 'ru' ? 'Местоположение получено' : 'Орналасу алынды');

        if (btn) {
          btn.disabled = false;
          btn.style.opacity = '1';
          btn.innerHTML = oldHtml;
        }
      },
      (err) => {
        let msgRu = 'Не удалось получить местоположение';
        if (err && err.code === 1) msgRu = 'Доступ к геолокации запрещён';
        if (err && err.code === 2) msgRu = 'Местоположение недоступно';
        if (err && err.code === 3) msgRu = 'Превышено время ожидания';

        showToast(getLang() === 'ru' ? msgRu : 'Орналасуды алу мүмкін болмады');

        if (btn) {
          btn.disabled = false;
          btn.style.opacity = '1';
          btn.innerHTML = oldHtml;
        }
      },
      { enableHighAccuracy: true, timeout: 12000, maximumAge: 0 }
    );
  }
  async function createOrderSubmit(ev) {
    // legacy hook (old sheet form) – redirect to new create-order flow
    if (ev && typeof ev.preventDefault === 'function') ev.preventDefault();
    await submitOrder();
  }

  function toggleOrderChat(forceOpen = null) {
    const modal = qs('#orderChatModal');
    if (!modal) return;
    if (forceOpen === true) modal.classList.add('active');
    else if (forceOpen === false) modal.classList.remove('active');
    else modal.classList.toggle('active');
  }

  async function openOrderChat(orderId) {
    const u = getLocalUser();
    const lang = getLang();
    if (!u) {
      showToast(t('needLoginFirst'));
      setTab('profile');
      return;
    }

    const oid = Number(orderId || 0);
    if (oid <= 0) return;

    ORDERS_STATE.currentOrderId = oid;
    window.CURRENT_ORDER_ID = oid;
    ORDERS_STATE.lastMsgId = 0;

    const cont = qs('#orderChatContainer');
    if (cont) cont.innerHTML = '';

    toggleOrderChat(true);

    try {
      const order = await apiGet('api/order_get.php?order_id=' + encodeURIComponent(String(oid)));
      ORDERS_STATE.currentOrder = order;

      const title = order?.service_title || t('chat');
      const otherName =
        u.role === 'master'
          ? order?.client_name || (lang === 'ru' ? 'Клиент' : 'Клиент')
          : order?.master_name || (lang === 'ru' ? 'Мастер' : 'Шебер');

      const st = String(order?.status || 'new');
      const statusMap = {
        kk: { new: t('statusNew'), in_progress: t('statusInProgress'), completed: t('statusCompleted'), cancelled: t('statusCancelled') },
        ru: { new: t('statusNew'), in_progress: t('statusInProgress'), completed: t('statusCompleted'), cancelled: t('statusCancelled') },
      };
      const stLabel = statusMap[lang]?.[st] || st;

      const hTitle = qs('#orderChatTitle');
      const hSub = qs('#orderChatSub');
      if (hTitle) hTitle.textContent = String(title);
      if (hSub) hSub.innerHTML = `${escapeHtml(otherName)} • <span class="status-text st-${escapeHtml(st)}">${escapeHtml(stLabel)}</span>`;

      // accept button
      const accBtn = qs('#orderAcceptBtn');
      if (accBtn) {
        const mid = Number(order?.master_id || 0);
        const meId = Number(u.id || 0);
        const canAccept = u.role === 'master' && st === 'new' && (mid === 0 || mid === meId);
        accBtn.style.display = canAccept ? 'inline-flex' : 'none';
        accBtn.textContent = t('orderAccept');
      }

      // finish button
      const finBtn = qs('#orderFinishBtn');
      if (finBtn) {
        const isMineClient = Number(order?.client_id || 0) === Number(u.id || 0);
        const isMineMaster = Number(order?.master_id || 0) === Number(u.id || 0);
        const cDone = Number(order?.client_done || 0) === 1;
        const mDone = Number(order?.master_done || 0) === 1;

        const canFinish =
          st === 'in_progress' &&
          ((u.role === 'client' && isMineClient && !cDone && Number(order?.master_id || 0) > 0) ||
            (u.role === 'master' && isMineMaster && !mDone));

        finBtn.style.display = canFinish ? 'inline-flex' : 'none';
        finBtn.textContent = t('orderFinish');
      }

      await fetchOrderMessages(true);
      await renderReviewBox(order);

      // poll
      if (ORDERS_STATE.pollTimer) clearInterval(ORDERS_STATE.pollTimer);
      ORDERS_STATE.pollTimer = setInterval(() => {
        fetchOrderMessages(false).catch(() => { });
      }, 2000);

      const inp = qs('#orderChatInput');
      const sendBtn = qs('#orderSendBtn');
      const chatClosed = st === 'completed' || st === 'cancelled';
      if (inp) {
        inp.disabled = chatClosed;
        inp.placeholder = chatClosed ? t('chatClosedForOrder') : t('chatInputPlaceholder');
        inp.onkeydown = (e) => {
          if (e.key === 'Enter') {
            e.preventDefault();
            sendOrderMessage();
          }
        };
        if (!chatClosed) inp.focus();
      }
      if (sendBtn) sendBtn.disabled = chatClosed;
    } catch (e) {
      showToast(t('orderChatOpenFail'));
    }
  }

  function closeOrderChat() {
    toggleOrderChat(false);
    if (ORDERS_STATE.pollTimer) {
      clearInterval(ORDERS_STATE.pollTimer);
      ORDERS_STATE.pollTimer = null;
    }
    ORDERS_STATE.currentOrderId = 0;
    window.CURRENT_ORDER_ID = null;
    ORDERS_STATE.currentOrder = null;
    ORDERS_STATE.lastMsgId = 0;
  }

  async function fetchOrderMessages(scrollToEnd) {
    const oid = ORDERS_STATE.currentOrderId;
    if (!oid) return;

    const url =
      'api/messages_list.php?order_id=' +
      encodeURIComponent(String(oid)) +
      '&after_id=' +
      encodeURIComponent(String(ORDERS_STATE.lastMsgId || 0));

    const data = await apiGet(url);
    const me = Number(data?.me || 0);
    const msgs = Array.isArray(data?.messages) ? data.messages : [];
    if (msgs.length === 0) return;

    const cont = qs('#orderChatContainer');
    if (!cont) return;

    msgs.forEach((m) => {
      const id = Number(m?.id || 0);
      if (id > ORDERS_STATE.lastMsgId) ORDERS_STATE.lastMsgId = id;

      const sender = Number(m?.sender_id || 0);
      const body = String(m?.body || '');

      const div = document.createElement('div');
      div.className = `chat-bubble ${sender === me ? 'chat-user' : 'chat-ai'}`;
      div.textContent = body;
      cont.appendChild(div);
    });

    if (scrollToEnd) cont.scrollTop = cont.scrollHeight;
  }

  async function sendOrderMessage() {
    const st = String(ORDERS_STATE.currentOrder?.status || 'new');
    if (st === 'completed' || st === 'cancelled') {
      showToast(t('orderAlreadyClosed'));
      return;
    }

    const inp = qs('#orderChatInput');
    const text = String(inp?.value || '').trim();
    if (!text) return;

    const oid = ORDERS_STATE.currentOrderId;
    if (!oid) return;

    if (inp) inp.value = '';

    try {
      await apiPost('api/messages_send.php', { order_id: oid, body: text });
      await fetchOrderMessages(true);
      loadOrdersList();
    } catch {
      showToast(t('messageNotSent'));
    }
  }

  async function acceptCurrentOrder() {
    const u = getLocalUser();
    if (!u || u.role !== 'master') return;

    const oid = ORDERS_STATE.currentOrderId;
    if (!oid) return;

    try {
      await apiPost('api/orders_accept.php', { order_id: oid });
      showToast(t('orderAccepted'));
      await openOrderChat(oid);
      loadOrdersList();
    } catch (e) {
      showToast(String(e.message) === 'bad_state' ? t('orderNotNew') : t('orderAcceptFail'));
    }
  }

  async function finishCurrentOrder() {
    const u = getLocalUser();
    if (!u || (u.role !== 'client' && u.role !== 'master')) return;

    const oid = ORDERS_STATE.currentOrderId;
    if (!oid) return;

    try {
      const res = await apiPost('api/order_finish.php', { order_id: oid });
      const both = !!(res?.both_done);

      showToast(both ? t('orderFullyCompleted') : t('orderWaitSecondConfirm'));

      await openOrderChat(oid);
      loadOrdersList();
      renderProfileRecent();
    } catch (e) {
      showToast(String(e.message) === 'bad_state' ? t('orderCannotFinishCancelled') : t('orderFinishFail'));
    }
  }

  // Reviews in chat after completed
  async function renderReviewBox(order) {
    const u = getLocalUser();
    const lang = getLang();
    const cont = qs('#orderChatContainer');
    if (!cont || !u || !order) return;

    const old = qs('#reviewBox');
    if (old) old.remove();

    if (u.role !== 'client') return;
    if (String(order.status || '') !== 'completed') return;

    const existsFlag = Number(order.review_exists || 0) === 1;
    if (existsFlag) return;

    try {
      const r = await apiGet('api/review_get.php?order_id=' + encodeURIComponent(String(order.id)));
      if (r) return;
    } catch {
      return;
    }

    const box = document.createElement('div');
    box.id = 'reviewBox';
    box.className = 'reviewBox';
    box.innerHTML = `
      <div class="reviewTitle">${escapeHtml(t('reviewLeave'))}</div>
      <div class="reviewRow">
        <select id="reviewRatingBox" class="reviewSelect">
          <option value="5" selected>5</option>
          <option value="4">4</option>
          <option value="3">3</option>
          <option value="2">2</option>
          <option value="1">1</option>
        </select>
        <button id="reviewSendBtnBox" class="reviewBtn">${escapeHtml(t('reviewSend'))}</button>
      </div>
      <textarea id="reviewBodyBox" class="reviewText" rows="3" placeholder="${escapeHtml(t('reviewBodyPlaceholder'))}"></textarea>
    `;

    cont.appendChild(box);
    cont.scrollTop = cont.scrollHeight;

    const sendBtn = qs('#reviewSendBtnBox');
    if (!sendBtn) return;

    sendBtn.onclick = async () => {
      try {
        sendBtn.disabled = true;

        const el = qs('#reviewRatingBox');
        const rating = el ? parseInt(String(el.value || ''), 10) : 0;
        const body = String(qs('#reviewBodyBox')?.value || '').trim();

        if (!Number.isInteger(rating) || rating < 1 || rating > 5) {
          sendBtn.disabled = false;
          showToast(t('reviewChooseRating'));
          return;
        }

        await apiPost('api/review_add.php', {
          order_id: Number(order.id),
          rating,
          body,
        });

        showToast(t('reviewSaved'));
        box.remove();
        await openOrderChat(Number(order.id));
      } catch (e) {
        sendBtn.disabled = false;
        const err = String(e.message || '');
        const msg =
          err === 'not_completed' || err === 'order_not_completed'
            ? t('reviewOnlyAfterCompleted')
            : err === 'exists' || err === 'review_already_exists'
              ? t('reviewAlreadyExists')
              : t('reviewSaveFail');
        showToast(msg);
      }
    };
  }

  // legacy inline handler compatibility
  async function sendReview() {
    const oid = Number(window.CURRENT_ORDER_ID || 0);
    if (!oid) {
      alert(t('orderNoSelected'));
      return;
    }

    const rating = Number(document.getElementById('reviewRating')?.value || 0);
    const body = (document.getElementById('reviewText')?.value || '').trim();

    if (!(rating >= 1 && rating <= 5)) {
      alert(t('orderRatingRange'));
      return;
    }

    await ensureCsrf();
    const params = new URLSearchParams();
    params.append('order_id', String(oid));
    params.append('rating', String(rating));
    params.append('body', body);

    const r = await fetch('api/review_add.php', {
      method: 'POST',
      credentials: 'same-origin',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
        'X-CSRF-Token': CSRF_TOKEN,
      },
      body: params,
    });

    const j = await r.json().catch(() => null);
    if (!r.ok || !j || j.ok !== true) {
      alert((j && j.error) ? j.error : 'Ошибка');
      return;
    }

    alert(t('reviewSent'));
    const block = document.getElementById('reviewBlock');
    if (block) block.style.display = 'none';
  }

  // =============================
  // AI chat
  // =============================
  function toggleAIChat() {
    const modal = qs('#aiModal');
    if (!modal) return;
    modal.classList.toggle('active');
  }

  function appendBubble(who, text, isHtml = false) {
    const container = qs('#chatContainer');
    if (!container) return;

    const div = document.createElement('div');
    div.className = `chat-bubble ${who === 'user' ? 'chat-user' : 'chat-ai'}`;
    if (isHtml) div.innerHTML = text;
    else div.textContent = text;

    container.appendChild(div);
    container.scrollTop = container.scrollHeight;
  }

  function appendTyping() {
    const container = qs('#chatContainer');
    if (!container) return null;

    const div = document.createElement('div');
    div.className = 'chat-bubble chat-ai';
    const id = `typing_${Date.now()}_${Math.random().toString(16).slice(2)}`;
    div.dataset.typingId = id;

    div.innerHTML = `<span class="typing-dots"><span>.</span><span>.</span><span>.</span></span>`;
    container.appendChild(div);
    container.scrollTop = container.scrollHeight;
    return id;
  }

  function removeTyping(id) {
    if (!id) return;
    const container = qs('#chatContainer');
    if (!container) return;
    const el = container.querySelector(`[data-typing-id="${id}"]`);
    if (el) el.remove();
  }

  function buildAiAnswer(userText) {
    const s = String(userText || '').toLowerCase();
    let rec = t('aiAskMore');

    if (/(кран|су|протеч|құбыр|унитаз)/i.test(s)) rec = t('aiToCatalogPlumbing');
    else if (/(розет|электр|свет|автомат|тоқ|жарық)/i.test(s)) rec = t('aiToCatalogElectric');
    else if (/(уборк|тазалық|терезе|клин)/i.test(s)) rec = t('aiToCatalogCleaning');

    return rec + t('aiTail');
  }

  function sendMessage() {
    const input = qs('#chatInput');
    const container = qs('#chatContainer');
    if (!input || !container) return;

    const text = String(input.value || '').trim();
    if (!text) return;

    appendBubble('user', text);
    input.value = '';

    const typingId = appendTyping();
    setTimeout(() => {
      removeTyping(typingId);
      appendBubble('ai', buildAiAnswer(text), true);
    }, 700);
  }

  // =============================
  // Profile Edit
  // =============================
  function openProfileEdit() {
    const modal = qs('#profileEditModal');
    const overlay = qs('#profileEditOverlay');
    if (!modal) return;

    let u = {};
    try {
      u = JSON.parse(localStorage.getItem(STORAGE.user) || '{}');
    } catch { }

    const setVal = (sel, v) => {
      const el = qs(sel);
      if (el) el.value = v ?? '';
    };

    setVal('#peName', u.name || qs('#profileName')?.textContent || '');
    setVal('#peCity', u.city || '');
    setVal('#peProfession', u.profession || '');
    setVal('#peExperience', u.experience ?? 0);
    setVal('#pePhone', u.phone || '');
    setVal('#peBio', u.bio || '');
    setVal('#peAvatarColor', u.avatar_color || '#1cb7ff');

    pickAvatarColor(String(u.avatar_color || '#1cb7ff'));

    const bio = qs('#peBio');
    const cnt = qs('#peBioCount');
    if (bio && cnt) cnt.textContent = bio.value.length + '/500';

    modal.classList.add('active');
    if (overlay) overlay.classList.add('active');
  }

  function closeProfileEdit() {
    const modal = qs('#profileEditModal');
    const overlay = qs('#profileEditOverlay');
    if (modal) modal.classList.remove('active');
    if (overlay) overlay.classList.remove('active');
  }

  function pickAvatarColor(color) {
    const inp = qs('#peAvatarColor');
    if (inp) inp.value = color;

    const prev = qs('#avPreview');
    if (prev) prev.style.background = color;

    qsa('.av-dot').forEach((d) => d.classList.toggle('selected', d.dataset.color === color));
  }

  async function uploadAvatarFile(input) {
    if (!input || !input.files || input.files.length === 0) return;
    const file = input.files[0];

    if (file.size > 5 * 1024 * 1024) {
      showToast(t('avatarFileTooBig'));
      input.value = '';
      return;
    }

    const formData = new FormData();
    formData.append('avatar', file);

    try {
      await ensureCsrf();
      const response = await fetch('api/avatar_upload.php', {
        method: 'POST',
        headers: { 'X-CSRF-Token': CSRF_TOKEN },
        body: formData,
        credentials: 'same-origin',
      });

      const res = await response.json().catch(() => null);
      if (response.ok && res?.ok) {
        showToast(t('avatarUpdated'));
        const data = res.data || {};

        let u = {};
        try {
          u = JSON.parse(localStorage.getItem(STORAGE.user) || '{}');
        } catch { }

        const newUserData = { ...u, avatar_url: data.avatar_url || data.avatarUrl || '' };
        localStorage.setItem(STORAGE.user, JSON.stringify(newUserData));
        _updateProfileDOM(newUserData);
      } else {
        showToast((getLang() === 'ru' ? 'Ошибка: ' : 'Қате: ') + (res?.error || 'http_' + response.status));
      }
    } catch {
      showToast(t('avatarUploadFail'));
    }

    input.value = '';
  }

  async function profileEditSubmit(ev) {
    ev.preventDefault();
    const btn = qs('#profileSaveBtn');
    if (btn) {
      btn.disabled = true;
      btn.style.opacity = '0.7';
    }

    const payload = {
      name: String(qs('#peName')?.value || '').trim(),
      city: String(qs('#peCity')?.value || '').trim(),
      profession: String(qs('#peProfession')?.value || '').trim(),
      experience: String(parseInt(qs('#peExperience')?.value || '0', 10)),
      phone: String(qs('#pePhone')?.value || '').trim(),
      bio: String(qs('#peBio')?.value || '').trim(),
      avatar_color: String(qs('#peAvatarColor')?.value || '#1cb7ff'),
    };

    if (!payload.name) {
      showToast(t('profileNameRequired'));
      if (btn) {
        btn.disabled = false;
        btn.style.opacity = '';
      }
      return;
    }

    try {
      const data = await apiPost('api/profile_update.php', payload);

      let u = {};
      try {
        u = JSON.parse(localStorage.getItem(STORAGE.user) || '{}');
      } catch { }

      const newUserData = {
        ...u,
        name: data?.name || payload.name,
        city: data?.city || payload.city,
        profession: data?.profession || payload.profession,
        experience: data?.experience ?? payload.experience,
        bio: data?.bio || payload.bio,
        phone: data?.phone || payload.phone,
        avatar_color: data?.avatar_color || payload.avatar_color,
        avatar_url: data?.avatar_url || u.avatar_url || '',
      };

      localStorage.setItem(STORAGE.user, JSON.stringify(newUserData));
      _updateProfileDOM(newUserData);

      closeProfileEdit();
      showToast(t('profileSaved'));
    } catch (e) {
      const err = String(e.message || '');
      const msg = err === 'bad_phone' ? t('phoneBadFormat') : t('profileSaveFail');
      showToast(msg);
    } finally {
      if (btn) {
        btn.disabled = false;
        btn.style.opacity = '';
      }
    }
  }

  function _updateProfileDOM(d) {
    const name = String(d.name || '');
    const city = String(d.city || '');
    const profession = String(d.profession || '');
    const experience = parseInt(String(d.experience || '0'), 10) || 0;
    const phone = String(d.phone || '');
    const bio = String(d.bio || '');
    const color = String(d.avatar_color || '#1cb7ff');
    const avUrl = String(d.avatar_url || '');

    const initial = name.trim().charAt(0).toUpperCase() || 'A';

    const nameEl = qs('#profileName');
    if (nameEl) nameEl.textContent = name || t('profileDefaultUser');

    const roleEl = qs('#profileRole');
    if (roleEl) {
      const cur = roleEl.textContent || '';
      if (cur.includes('•')) roleEl.textContent = cur.split('•')[0].trim() + ' • ' + (city || '—');
      else roleEl.textContent = (city || '—');
    }

    const profEl = qs('#profileProfession');
    if (profEl) {
      if (profession) {
        profEl.style.display = '';
        profEl.textContent = profession + (experience > 0 ? ' • ' + experience + ' ' + t('yearsSuffix') : '');
      } else {
        profEl.style.display = 'none';
        profEl.textContent = '';
      }
    }

    const bioEl = qs('#profileBio');
    if (bioEl) {
      if (bio) {
        bioEl.style.display = '';
        bioEl.textContent = bio;
      } else {
        bioEl.style.display = 'none';
        bioEl.textContent = '';
      }
    }

    const phoneEl = qs('#profilePhone');
    if (phoneEl) {
      if (phone) {
        phoneEl.style.display = '';
        phoneEl.textContent = phone;
      } else {
        phoneEl.style.display = 'none';
        phoneEl.textContent = '';
      }
    }

    const av = qs('#profileAvatar');
    if (av) {
      av.style.background = color;
      if (avUrl) {
        av.style.backgroundImage = `url('${avUrl}')`;
        av.style.backgroundSize = 'cover';
        av.style.backgroundPosition = 'center';
        av.textContent = '';
      } else {
        av.style.backgroundImage = '';
        av.textContent = initial;
      }
    }

    const prev = qs('#avPreview');
    if (prev) prev.style.background = color;
  }

  // =============================
  // Utils
  // =============================
  function escapeHtml(str) {
    return String(str)
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#039;');
  }

  function escapeJs(str) {
    return String(str).replaceAll('\\', '\\\\').replaceAll("'", "\\'");
  }

  function formatMoney(n) {
    const v = Number(n ?? 0);
    if (!Number.isFinite(v)) return '0';
    return String(Math.trunc(v)).replace(/\B(?=(\d{3})+(?!\d))/g, ' ');
  }

  function formatShortDate(dtStr) {
    const s = String(dtStr || '');
    const d = s.slice(0, 10);
    const parts = d.split('-');
    if (parts.length !== 3) return d || '';
    const [y, m2, d2] = parts;
    return `${d2}.${m2}.${y}`;
  }

  // =============================
  // expose globals
  // =============================
  window.t = t;
  window.tr = tr;

  window.showToast = showToast;
  window.setLanguage = setLanguage;
  window.toggleTheme = toggleTheme;
  window.toggleMenu = toggleMenu;
  window.setTab = setTab;
  window.primaryAction = primaryAction;
  window.logout = logout;
  window.switchRole = switchRole;
  function showAuth(mode) {
    const m = String(mode || 'login').toLowerCase();
    const tabLogin = qs('#authTabLogin');
    const tabReg = qs('#authTabReg');
    const fLogin = qs('#authLogin');
    const fReg = qs('#authReg');

    if (tabLogin) tabLogin.classList.toggle('active', m === 'login');
    if (tabReg) tabReg.classList.toggle('active', m === 'reg');

    if (fLogin) fLogin.classList.toggle('hidden', m !== 'login');
    if (fReg) fReg.classList.toggle('hidden', m !== 'reg');
  }

  window.showAuth = showAuth;

  window.openOrdersTab = openOrdersTab;
  window.openOrderCreate = openOrderCreate;
  window.toggleOrderCreate = toggleOrderCreate;
  window.createOrderSubmit = createOrderSubmit;

  // create order (home.html UI)
  window.openCreateOrder = openCreateOrder;
  window.closeCreateOrder = closeCreateOrder;

  // ---------- Photo upload helpers (used in order create form) ----------
  // These functions were referenced but never defined — fixed here.
  let _photoFiles = [];

  function handlePhotoUpload(input) {
    if (!input || !input.files) return;
    const files = Array.from(input.files);
    const MAX = 5;
    const remaining = MAX - _photoFiles.length;
    if (remaining <= 0) {
      showToast(getLang() === 'ru' ? 'Максимум 5 фото' : 'Максимум 5 сурет');
      input.value = '';
      return;
    }
    files.slice(0, remaining).forEach(file => {
      if (!file.type.startsWith('image/')) return;
      if (file.size > 10 * 1024 * 1024) return;
      _photoFiles.push(file);
    });
    input.value = '';
    _renderPhotoPreview();
  }

  function removePhoto(idx) {
    _photoFiles.splice(idx, 1);
    _renderPhotoPreview();
  }

  function _renderPhotoPreview() {
    const container = qs('#photoPreview') || qs('#orderPhotoPreview');
    if (!container) return;
    container.innerHTML = _photoFiles.map((f, i) => {
      const url = URL.createObjectURL(f);
      return `<div style="position:relative;width:72px;height:72px;border-radius:10px;overflow:hidden;flex-shrink:0;">
        <img src="${url}" style="width:100%;height:100%;object-fit:cover;">
        <button type="button" onclick="removePhoto(${i})" style="position:absolute;top:3px;right:3px;background:rgba(0,0,0,.55);border:none;color:#fff;border-radius:50%;width:20px;height:20px;font-size:14px;line-height:1;cursor:pointer;display:flex;align-items:center;justify-content:center;">×</button>
      </div>`;
    }).join('');
  }
  // -------------------------------------------------------------------

  window.handlePhotoUpload = handlePhotoUpload;
  window.removePhoto = removePhoto;
  window.submitOrder = submitOrder;
  window.renderMyOrders = renderMyOrders;
  window.switchOrderTab = switchOrderTab;
  window.ocDetectLocation = ocDetectLocation;
  window.openOrderChat = openOrderChat;
  window.closeOrderChat = closeOrderChat;
  window.sendOrderMessage = sendOrderMessage;
  window.acceptCurrentOrder = acceptCurrentOrder;
  window.finishCurrentOrder = finishCurrentOrder;

  window.toggleAIChat = toggleAIChat;
  window.sendMessage = sendMessage;

  window.renderServices = renderServices;
  window.toggleAccordion = toggleAccordion;

  window.openProfileEdit = openProfileEdit;
  window.closeProfileEdit = closeProfileEdit;
  window.openMasterProfile = openMasterProfile;
  window.closeMasterProfile = closeMasterProfile;
  window.pickAvatarColor = pickAvatarColor;
  window.uploadAvatarFile = uploadAvatarFile;
  window.profileEditSubmit = profileEditSubmit;

  window.sendReview = sendReview;

  // =============================
  // init
  // =============================
  document.addEventListener('DOMContentLoaded', () => {
    syncThemeToggle();

    // set lang + translate
    setLanguage(getLang());

    // tab param
    try {
      const p = new URLSearchParams(window.location.search);
      const tab = p.get('tab');
      if (tab) setTab(tab);

      // Автооткрытие SMS модалки если нужна верификация
      const urlParams = new URLSearchParams(window.location.search);
      if (urlParams.get('sms_required') === '1') {
        const modal = qs('#smsVerifyModal');
        const overlay = qs('#smsVerifyOverlay');
        if (modal) modal.classList.add('active');
        if (overlay) overlay.classList.add('active');
      }

      const auth = p.get('auth');
      if (auth) {
        const map = {
          login_ok: { kk: 'Кіру сәтті өтті', ru: 'Вход выполнен' },
          login_ok:    { kk: 'Кіру сәтті өтті', ru: 'Вход выполнен' },
          login_bad:   { kk: 'Email немесе пароль қате', ru: 'Неверный email или пароль' },
          login_fail:  { kk: 'Email немесе пароль қате', ru: 'Неверный email или пароль' },
          login_empty: { kk: 'Email және пароль енгізіңіз', ru: 'Введите email и пароль' },
          login_blocked: { kk: 'Аккаунт бұғатталған', ru: 'Аккаунт заблокирован' },
          reg_ok:      { kk: 'Тіркелу сәтті өтті', ru: 'Регистрация успешна' },
          reg_empty:   { kk: 'Барлық өрістерді толтырыңыз', ru: 'Заполните все поля' },
          reg_email:   { kk: 'Email қате', ru: 'Неверный email' },
          reg_passlen: { kk: 'Пароль кемінде 6 символ', ru: 'Пароль минимум 6 символов' },
          reg_passmatch: { kk: 'Пароль сәйкес емес', ru: 'Пароли не совпадают' },
          reg_exists:  { kk: 'Бұл логин тіркелген', ru: 'Этот логин уже занят' },
          reg_login_invalid: { kk: 'Логин дұрыс емес (3-32 символ)', ru: 'Логин некорректен (3-32 символа)' },
          reg_error:   { kk: 'Тіркелу қатесі, қайталаңыз', ru: 'Ошибка регистрации, попробуйте снова' },
          blocked:     { kk: 'Аккаунт бұғатталған', ru: 'Аккаунт заблокирован' },
          logout:      { kk: 'Шықтыңыз', ru: 'Вы вышли' },
        }[auth];
        if (map) showToast(getLang() === 'ru' ? map.ru : map.kk);
      }
    } catch { }

    loadUser();

    // 1. Объявляем функцию ГЛОБАЛЬНО (вне всех условий)
    window.handleAuthLater = function() {
        console.log("Кнопка 'Позже' нажата. Закрываю...");

        const modal = document.getElementById('smsVerifyModal');
        const overlay = document.getElementById('smsVerifyOverlay');

        // Убираем и через стили, и через классы (на всякий случай)
        if (modal) {
            modal.style.display = 'none';
            modal.classList.remove('active');
        }
        if (overlay) {
            overlay.style.display = 'none';
            overlay.classList.remove('active');
        }

        // Чистим дубликаты, если они есть
        document.querySelectorAll('[id="smsVerifyModal"]').forEach(el => {
            el.style.display = 'none';
            el.classList.remove('active');
        });
        document.querySelectorAll('[id="smsVerifyOverlay"]').forEach(el => {
            el.style.display = 'none';
            el.classList.remove('active');
        });
    };

    // 2. Оживляем клик по оверлею (черному фону)
    const overlayEl = document.getElementById('smsVerifyOverlay');
    if (overlayEl) {
        overlayEl.onclick = function() { window.handleAuthLater(); };
        overlayEl.style.cursor = 'pointer';
    }

    // ping
    setInterval(() => {
      const u = getLocalUser();
      if (!u) return;
      apiPost('api/ping.php', {}).catch(() => { });
    }, 30000);

    applyProfileStatsFromServer();
    renderServices('');
    renderProfileRecent();
    renderMyOrders().catch(() => {});

    const search = qs('#courseSearch');
    if (search) search.addEventListener('input', (e) => renderServices(e.target.value));

    const chatInput = qs('#chatInput');
    if (chatInput) {
      chatInput.addEventListener('keydown', (e) => {
        if (e.key === 'Enter') sendMessage();
      });
    }
  }); // Конец DOMContentLoaded
}
)();