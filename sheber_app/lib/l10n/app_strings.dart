/// Simple compile-time localization for KZ / RU.
/// Usage: S.of(context).hello  — requires Consumer[AppState] in tree,
/// or use S.lang(state.language).hello directly.
class S {
  final String lang;
  const S._(this.lang);

  factory S.lang(String lang) => S._(lang);

  bool get isKz => lang == 'kz';

  // ── Common ────────────────────────────────────────────────────
  String get appName => 'Sheber.kz';
  String get error => isKz ? 'Қате' : 'Ошибка';
  String get cancel => isKz ? 'Болдырмау' : 'Отмена';
  String get confirm => isKz ? 'Растау' : 'Подтвердить';
  String get loading => isKz ? 'Жүктелуде...' : 'Загрузка...';
  String get noData => isKz ? 'Деректер жоқ' : 'Нет данных';
  String get retry => isKz ? 'Қайталау' : 'Повторить';
  String get select => isKz ? 'Таңдау' : 'Выбрать';
  String get all => isKz ? 'Барлығы' : 'Все';
  String get notSelected => isKz ? 'Таңдалмаған' : 'Не выбран';
  String get loadError => isKz ? 'Деректерді жүктеу қатесі' : 'Ошибка загрузки данных';
  String get tryAgain => isKz ? 'Қайтадан көру' : 'Попробовать снова';

  // ── Home tab ──────────────────────────────────────────────────
  String get hello => isKz ? 'Сәлем' : 'Привет';
  String get appTagline => isKz ? 'Жылдам шебер табу сервисі' : 'Сервис быстрого поиска мастера';
  String get searchFree => isKz ? 'ТЕГІН ІЗДЕУ' : 'БЕСПЛАТНЫЙ ПОИСК';
  String get findNearby => isKz ? 'Жаныңыздағы шеберді табыңыз' : 'Найдите мастера рядом с вами';
  String get selectCity => isKz
      ? 'Қалаңызды таңдаңыз — тапсырыс жасау, шеберлердің ұсыныстары және чат барлық қолданба ішінде.'
      : 'Выберите город — заказы, отклики мастеров и чат проходят внутри приложения.';
  String get cityLabel => isKz ? 'Қала' : 'Город';
  String get cityShortLabel => isKz ? 'ҚАЛА' : 'ГОРОД';
  String get findMaster => isKz ? 'Шебер табу' : 'Найти мастера';
  String get noRegNeeded => isKz ? 'Тіркелу қажет емес — іздеу тегін' : 'Регистрация не нужна — поиск бесплатный';
  String get howItWorks => isKz ? 'Қалай жұмыс істейді' : 'Как это работает';
  String get step1Title => isKz ? 'Тапсырыс жасаңыз' : 'Создайте заказ';
  String get step1Sub => isKz
      ? 'Негізгі беттегі + батырмасы: сипаттама, мекенжай, баға, фото.'
      : 'Кнопка «+» на главной: опишите задачу, адрес, бюджет, при необходимости фото.';
  String get step2Title => isKz ? 'Шебердің ұсынысын күтіңіз' : 'Дождитесь откликов';
  String get step2Sub => isKz
      ? 'Ұсыныстар келеді — бірін қабылдаңыз. Оған дейін клиент чатқа жаза алмайды.'
      : 'Мастера присылают цену. Примите одну — до этого чат для клиента закрыт.';
  String get step3Title => isKz ? 'Чатта үйлестіріп, аяқтаңыз' : 'Чат и завершение';
  String get step3Sub => isKz
      ? 'Жұмыс біткенде екі жақ та «растау» батырмасын басады — содан кейін тапсырыс аяқталады.'
      : 'Когда работа сделана, клиент и мастер нажимают «галочку» — заказ закрывается, когда подтвердят оба.';
  /// Клиент: чат закрыт, пока нет назначенного мастера (статус жаңа).
  String get chatLockedWaitingMaster => isKz
      ? 'Шебер таңдалғанша чат жабық. Ұсынысты қабылдаңыз.'
      : 'Чат откроется после того, как вы примете ставку мастера.';
  /// Чат закрыт: заказ завершён и клиент поставил 5★.
  String get chatClosedPerfectHint => isKz
      ? '5 жұлдыз — тапсырыс сәтті аяқталды. Чат жабық.'
      : 'Оценка 5★ — заказ успешно закрыт. Чат недоступен.';
  String get chatSendErrorClosedPerfect => isKz
      ? '5 жұлдыз қойылған — хабарлама жіберу мүмкін емес.'
      : 'При оценке 5★ отправка сообщений отключена.';
  String get reviewClientBannerTitle => isKz ? 'Сіздің пікіріңіз' : 'Ваш отзыв';
  String get reviewEditButton => isKz ? 'Өзгерту' : 'Изменить';
  String get reviewFiveStarsImmutable => isKz
      ? 'Толық қанағаттану — пікірді өзгерту мүмкін емес.'
      : 'Полная оценка — отзыв нельзя изменить.';
  String get reviewEditDeadlinePrefix => isKz ? 'Өзгертуге дейін: ' : 'Можно изменить ещё ';
  String get masterLowRatingTitle => isKz ? 'Клиент толық қанағаттанбаған сияқты' : 'Клиент, похоже, не до конца доволен';
  String get masterLowRatingSubtitle => isKz
      ? 'Төменгі баға қойылған. Мәселені чатта талқылап, шешім табыңыз. Клиент 5 жұлдыз қойғанда чат автоматты жабылады.'
      : 'Ставка ниже 5★. Обсудите ситуацию в чате. Когда клиент поставит 5★, чат закроется автоматически.';
  String get clientConfirmFinish => isKz ? 'Орындалғанын растау' : 'Подтвердить выполнение';
  String get finishErrorBadState => isKz
      ? 'Әлі аяқтауға болмайды (тапсырыс күйін тексеріңіз).'
      : 'Сейчас нельзя завершить (проверьте статус заказа).';
  String get finishErrorForbidden => isKz ? 'Рұқсат жоқ' : 'Нет доступа';
  String get finishErrorGeneric => isKz ? 'Сервер қатесі' : 'Ошибка сервера';
  String get categories => isKz ? 'Санаттар' : 'Категории';

  // Category labels
  String get catPlumbing => isKz ? 'Сантехника' : 'Сантехника';
  String get catElectric => isKz ? 'Электрик' : 'Электрик';
  String get catRepair => isKz ? 'Жөндеу' : 'Ремонт';
  String get catCleaning => isKz ? 'Тазалық' : 'Уборка';
  String get catWindows => isKz ? 'Терезе' : 'Окна';
  String get catPainting => isKz ? 'Бояу' : 'Покраска';
  String get catCarpentry => isKz ? 'Ағаш' : 'Плотник';
  String get catOther => isKz ? 'Басқа' : 'Другое';

  // ── Navigation ────────────────────────────────────────────────
  String get navHome => isKz ? 'Басты' : 'Главная';
  String get navChat => isKz ? 'Чат' : 'Чат';

  // ── Боковое меню (drawer) ────────────────────────────────────
  String get navDrawerSubtitle => isKz ? 'Мәзірді ашыңыз' : 'Меню навигации';
  String get navDrawerHomeHint =>
      isKz ? 'Басу — басты бетке' : 'Нажмите — на главную';
  String get navDrawerMastersInCity =>
      isKz ? 'Қаладағы шеберлер' : 'Мастера в нашем городе';
  String get navDrawerMastersDirect =>
      isKz ? 'Тікелей байланыс' : 'Прямая связь с мастерами';
  String get navDrawerMastersDirectSub =>
      isKz ? 'Қоңырау, хабарлама' : 'Звонок и переписка';
  String get navDrawerFaq => isKz ? 'Сұрақ-жауап' : 'Вопросы и ответы';
  String get navDrawerMessages => isKz ? 'Хабарламалар' : 'Сообщения';
  String get navDrawerLightTheme => isKz ? 'Жарық тема' : 'Светлая тема';
  String get navDrawerDarkTheme => isKz ? 'Қараңғы тема' : 'Тёмная тема';
  String get corporateFooterLine1 => 'Mili-tech';
  String get corporateFooterLine2 =>
      isKz ? 'қолдау командасы' : 'служба поддержки продукта';
  String get faqHowToOrderQ => isKz ? 'Тапсырыс қалай жасалады?' : 'Как сделать заказ?';
  String get faqHowToOrderA => isKz
      ? '«Тапсырыс жасау» түймесін басыңыз, сипаттаманы толтырыңыз — шеберлер ұсыныс жібереді.'
      : 'Нажмите «Создать заказ», опишите задачу — мастера отправят предложения.';
  String get faqHowToPayQ => isKz ? 'Төлем қалай жүреді?' : 'Как проходит оплата?';
  String get faqHowToPayA => isKz
      ? 'Қазіргі уақытта келісім шебермен тікелей — қолма-қол немесе қолайлы әдіс.'
      : 'Сейчас договорённость с мастером напрямую — наличные или удобный вам способ.';
  String get faqSupportQ => isKz ? 'Қолдау қалай байланысуға болады?' : 'Как связаться с поддержкой?';
  String get faqSupportA => isKz
      ? 'Мәзірдегі «Қолдау қызметі» арқылы WhatsApp немесе қолданба ішіндегі чат.'
      : 'Через пункт «Служба поддержки» в меню — WhatsApp или чат в приложении.';
  String get navMasters => isKz ? 'Шеберлер' : 'Мастера';
  String get navProfile => isKz ? 'Профиль' : 'Профиль';

  /// Ошибка открытия заказа из push (язык из [AppState]).
  String get pushOrderOpenError =>
      isKz ? 'Тапсырысты ашу мүмкін емес' : 'Не удалось открыть заказ';

  // ── Masters tab ───────────────────────────────────────────────
  String get mastersTitle => isKz ? 'Шеберлер' : 'Мастера';
  String get searchMastersHint =>
      isKz ? 'Аты немесе мамандық бойынша іздеу...' : 'Поиск по имени или специальности...';
  String get mastersSubtitle => isKz ? 'Іздеу үшін қаланы таңдаңыз' : 'Выберите город для поиска';
  String mastersSubtitleCity(String city) => isKz ? '$city қаласы' : 'Город $city';
  String get mastersSubtitleAll =>
      isKz ? 'Барлық қалалардағы тіркелген шеберлер' : 'Зарегистрированные мастера по всем городам';
  String get noMastersFound => isKz ? 'Шеберлер табылмады' : 'Мастера не найдены';
  String get tryAdjustSearchOrFilters =>
      isKz ? 'Іздеуді немесе сүзгілерді өзгертіп көріңіз' : 'Измените поиск или фильтры';
  String get selectCityBtn => isKz ? 'Қаланы таңдау' : 'Выбрать город';
  String get noMastersInCity => isKz ? 'Бұл қалада шебер жоқ' : 'В этом городе нет мастеров';
  String get tryOtherCity => isKz ? 'Басқа қаланы таңдап көріңіз' : 'Попробуйте другой город';
  String get startSearch => isKz ? 'Шебер іздеуді бастаңыз' : 'Начните поиск мастера';
  String get searchInstruction => isKz ? 'Қаланы таңдаңыз — сол жердегі\nбарлық шеберлерді көрсетеміз.' : 'Выберите город — покажем всех\nзарегистрированных мастеров.';
  String get callBtn => isKz ? 'Қоңырау' : 'Звонок';
  String get years => isKz ? 'жыл' : 'лет';

  // ── Chat tab ──────────────────────────────────────────────────
  String get messagesTitle => isKz ? 'Хабарламалар' : 'Сообщения';
  String get chatWithMasters => isKz ? 'Шеберлермен чат' : 'Чат с мастерами';
  String get support => isKz ? 'Қолдау' : 'Поддержка';
  String get loginToUseChat => isKz ? 'Чатты пайдалану үшін кіріңіз' : 'Войдите, чтобы использовать чат';
  String get chatWillBeHere => isKz ? 'Шеберлермен чат мұнда болады' : 'Чат с мастерами будет здесь';
  String get typeMessage => isKz ? 'Хабарлама жазыңыз...' : 'Напишите сообщение...';
  String get aiOnline => isKz ? 'AI көмекшісі онлайн' : 'AI-помощник онлайн';
  String get aiIntro => isKz ? 'Сәлем! Мен Sheber.kz AI көмекшісімін.\nҮйде не сынды? Мәселені жазсаңыз, шебер тауып беремін.' : 'Привет! Я AI-помощник Sheber.kz.\nЧто сломалось дома? Опишите проблему — найду мастера.';
  String get aiReply => isKz ? 'Сіздің мәселеңіз қабылданды. Жақын шеберді іздеп жатырмын...' : 'Ваша проблема принята. Ищу ближайшего мастера...';

  // ── Profile tab ───────────────────────────────────────────────
  String get personalCabinet => isKz ? 'Жеке кабинет' : 'Личный кабинет';
  String get loginViaSMS => isKz ? 'SMS арқылы кіру' : 'Войти через SMS';
  String get loginTabLabel => isKz ? 'Кіру' : 'Войти';
  String get registerTabLabel => isKz ? 'Тіркелу' : 'Регистрация';
  String get loginInfo => isKz ? 'SMS арқылы кіру үшін телефон нөмірін пайдаланыңыз' : 'Используйте номер телефона для входа через SMS';
  String get userDefault => isKz ? 'Пайдаланушы' : 'Пользователь';
  String get masterRoleLabel => isKz ? 'Шебер' : 'Мастер';
  String get clientRoleLabel => isKz ? 'Клиент' : 'Клиент';
  String get ordersLabel => isKz ? 'Тапсырыстар' : 'Заказы';
  String get reviewsLabel => isKz ? 'Пікірлер' : 'Отзывы';
  String get ratingLabel => isKz ? 'Рейтинг' : 'Рейтинг';
  String get settingsSection => isKz ? 'Баптаулар' : 'Настройки';
  String get editProfile => isKz ? 'Профильді өзгерту' : 'Редактировать профиль';
  String get changeRole => isKz ? 'Рөлді өзгерту' : 'Сменить роль';
  String currentRoleLabel(String role) => isKz
      ? 'Қазір: ${role == "master" ? "Шебер" : "Клиент"}'
      : 'Сейчас: ${role == "master" ? "Мастер" : "Клиент"}';
  String get notificationsLabel => isKz ? 'Хабарландырулар' : 'Уведомления';
  String get additionalSettings => isKz ? 'Қосымша параметрлер' : 'Дополнительно';
  String get darkModeLabel => isKz ? 'Түнгі режим' : 'Тёмная тема';
  String get languageLabel => isKz ? 'Тіл' : 'Язык';
  String get logoutLabel => isKz ? 'Шығу' : 'Выйти';
  String get logoutConfirm => isKz ? 'Шынымен шыққыңыз келе ме?' : 'Вы действительно хотите выйти?';
  String get loginHintText => isKz ? 'Логин немесе Email' : 'Логин или Email';
  String get passwordHint => isKz ? 'Құпиясөз' : 'Пароль';
  String get fullNameHint => isKz ? 'Аты-жөні' : 'Имя и фамилия';
  String get enterLoginBtn => isKz ? 'Кіру' : 'Войти';
  String get registerBtn => isKz ? 'Тіркелу' : 'Зарегистрироваться';

  // ── Client home ───────────────────────────────────────────────
  String get create => isKz ? 'Жасау' : 'Создать';
  String get myOrders => isKz ? 'Тапсырыстарым' : 'Мои заказы';
  String get whatToFix => isKz ? 'Не жөндеу керек?' : 'Что нужно починить?';
  String get createOrder => isKz ? 'Тапсырыс жасау' : 'Создать заказ';
  String get myOrdersTitle => isKz ? 'Менің тапсырыстарым' : 'Мои заказы';
  String get noOrdersYet => isKz ? 'Тапсырыстар жоқ' : 'Заказов пока нет';
  String get masterLabel => isKz ? 'Шебер:' : 'Мастер:';

  // ── Create order ──────────────────────────────────────────────
  String get newOrder => isKz ? 'Жаңа тапсырыс' : 'Новый заказ';
  String get category => isKz ? 'Санат' : 'Категория';
  String get describeIssue => isKz ? 'Мәселені сипаттаңыз' : 'Опишите проблему';
  String get address => isKz ? 'Мекенжай' : 'Адрес';
  String get budget => isKz ? 'Бюджет (₸)' : 'Бюджет (₸)';
  String get submitOrder => isKz ? 'Тапсырысты жіберу' : 'Отправить заказ';
  String get orderMapPreview => isKz ? 'Картадағы орын' : 'Точка на карте';
  String get orderGeocodingHint =>
      isKz ? 'Мекенжайды енгізіңіз — картада көрсетеміз' : 'Введите адрес — покажем точку на карте';
  String get orderGeocodingLoading =>
      isKz ? 'Картада іздеу...' : 'Ищем на карте...';
  String get orderGeocodeNotFound => isKz
      ? 'Картада табылмады — тапсырысты жіберуге болады'
      : 'На карте не найдено — заказ всё равно можно отправить';

  // ── Master home ───────────────────────────────────────────────
  String get newOrders => isKz ? 'Жаңа тапсырыстар' : 'Новые заказы';
  String get noNewOrders => isKz ? 'Жаңа тапсырыстар жоқ' : 'Новых заказов пока нет';
  String get noOrdersInThisCategory => isKz ? 'Бұл санатта тапсырыс жоқ' : 'Нет заказов в этой категории';
  String get acceptOrder => isKz ? 'Тапсырысты қабылдау' : 'Принять заказ';
  String get orderAccepted => isKz ? 'Тапсырыс қабылданды!' : 'Заказ принят!';
  String get myWork => isKz ? 'Менің жұмыстарым' : 'Мои работы';

  // ── Chat ──────────────────────────────────────────────────────
  String get noMessages => isKz ? 'Хабарлама жоқ' : 'Нет сообщений';
  String get messageHint => isKz ? 'Хабарлама...' : 'Сообщение...';
  String get orderFinished => isKz ? 'Тапсырыс аяқталды!' : 'Заказ завершён!';
  String get masterMapWhere => isKz ? 'Шебер қайда?' : 'Где мастер?';
  String get masterMapTitle => isKz ? 'Шебер орны' : 'Местоположение мастера';
  String get masterMapNoLocation =>
      isKz ? 'Геолокация әлі жіберілмеген. Шебер жолда болғанда картада көрінеді.'
          : 'Геолокация ещё не передана. Точка появится, когда мастер в пути.';
  String get masterMapStale =>
      isKz ? 'Соңғы орын 10 минут бұрын жаңартылған' : 'Последнее обновление позиции более 10 мин назад';
  String get orderMapWorkSite => isKz ? 'Жұмыс орны' : 'Место работ';
  String get orderMapMasterPin => isKz ? 'Шебер' : 'Мастер';

  // ── Auth / Profile ────────────────────────────────────────────
  String get phone => isKz ? 'Телефон' : 'Телефон';
  String get sendCode => isKz ? 'Код жіберу' : 'Отправить код';
  String get enterCode => isKz ? 'Кодты енгізіңіз' : 'Введите код';
  String get verify => isKz ? 'Растау' : 'Подтвердить';
  String get logout => isKz ? 'Шығу' : 'Выйти';
  String get profile => isKz ? 'Профиль' : 'Профиль';
  String get name => isKz ? 'Аты' : 'Имя';
  String get save => isKz ? 'Сақтау' : 'Сохранить';

  // ── Role select ───────────────────────────────────────────────
  String get iAmClient => isKz ? 'Мен клиентпін' : 'Я клиент';
  String get iAmMaster => isKz ? 'Мен шебермін' : 'Я мастер';

  // ── Profession select ─────────────────────────────────────────
  String get professionTitle => isKz ? 'Мамандығыңызды таңдаңыз' : 'Выберите специализацию';
  String get professionSubtitle => isKz ? 'Клиенттер сізді дәлірек табады' : 'Клиенты найдут вас точнее';

  // ── Diploma screen ────────────────────────────────────────────
  String get diplomaTitle => isKz ? 'Дипломдар мен куәліктер' : 'Дипломы и сертификаты';
  String get diplomaSubtitle => isKz ? 'Клиенттер сізге сенімді болады' : 'Клиенты будут доверять вам больше';
  String get skipForNow => isKz ? 'Кейінге қалдыру' : 'Пропустить';
  String get addDiploma => isKz ? 'Диплом қосу' : 'Добавить диплом';
  String get saveAndContinue => isKz ? 'Сақтау және жалғастыру' : 'Сохранить и продолжить';
  String get diplomaHint => isKz ? 'Диплом / куәлік атауы' : 'Название диплома / сертификата';

  // ── Rating dialog ─────────────────────────────────────────────
  String get rateTheMaster => isKz ? 'Шеберді бағалаңыз' : 'Оцените мастера';
  String get rateSubtitle => isKz ? 'Сіздің пікіріңіз басқаларға көмектеседі' : 'Ваш отзыв поможет другим';
  String get impressionHint => isKz ? 'Шебер туралы пікіріңіз...' : 'Ваши впечатления о мастере...';
  String get sendRating => isKz ? 'Бағалауды жіберу' : 'Отправить оценку';
  String get skipRating => isKz ? 'Бағаламай аяқтау' : 'Завершить без оценки';
  String get masterConfirmFinish => isKz ? 'Тапсырысты аяқтайсыз ба?' : 'Завершить заказ?';
  String get yes => isKz ? 'Иә' : 'Да';
  String get orderFinishedSuccess => isKz ? 'Тапсырыс сәтті аяқталды!' : 'Заказ успешно завершён!';

  // ── Edit profile ──────────────────────────────────────────────
  String get editProfileTitle => isKz ? 'Профильді өзгерту' : 'Редактировать профиль';
  String get saveChanges => isKz ? 'Сақтау' : 'Сохранить';
  String get yourNameHint => isKz ? 'Атыңыз' : 'Ваше имя';
  String get yourEmailHint => 'Email';
  String get yourProfessionHint => isKz ? 'Мамандығыңыз' : 'Специализация';
  String get changePassword => isKz ? 'Пароль өзгерту' : 'Изменить пароль';
  String get newPassword => isKz ? 'Жаңа пароль' : 'Новый пароль';
  String get passwordChanged => isKz ? 'Пароль сәтті өзгертілді' : 'Пароль успешно изменён';
  String get changePasswordButton => isKz ? 'Құпиясөзді өзгерту' : 'Сменить пароль';
  String get changePasswordTitle => isKz ? 'Құпиясөзді өзгерту' : 'Смена пароля';
  String get currentPasswordLabel => isKz ? 'Ағымдағы құпиясөз' : 'Текущий пароль';
  String get newPasswordLabel => isKz ? 'Жаңа құпиясөз' : 'Новый пароль';
  String get repeatPasswordLabel => isKz ? 'Жаңа құпиясөзді қайталаңыз' : 'Повторите новый пароль';
  String get passwordsDoNotMatch => isKz ? 'Құпиясөздер сәйкес емес' : 'Пароли не совпадают';
  String get confirmPasswordChangeTitle =>
      isKz ? 'Растау' : 'Подтверждение';
  String get confirmPasswordChangeBody =>
      isKz
          ? 'Құпиясөзді шынымен өзгерткіңіз келе ме? Бұрынғы пароль жарамай қалады.'
          : 'Точно сменить пароль? Старый пароль перестанет действовать.';
  String get wrongCurrentPassword =>
      isKz ? 'Ағымдағы құпиясөз дұрыс емес' : 'Неверный текущий пароль';
  String get currentPasswordRequired =>
      isKz ? 'Ағымдағы құпиясөзді енгізіңіз' : 'Введите текущий пароль';
  String get changePasswordFailed =>
      isKz ? 'Құпиясөзді өзгерту сәтсіз аяқталды' : 'Не удалось сменить пароль';
  String get firstPasswordSubtitle =>
      isKz
          ? 'Email арқылы кіру үшін құпиясөз орнатыңыз (кемінде 6 таңба).'
          : 'Задайте пароль для входа по email (не менее 6 символов).';

  // ── Gamification ──────────────────────────────────────────────
  String get achievementsTitle => isKz ? 'Жетістіктер' : 'Достижения';
  String get tierNewcomer => isKz ? 'Жаңадан бастаушы' : 'Новичок';
  String get tierActive => isKz ? 'Белсенді Шебер' : 'Активный Мастер';
  String get tierProfessional => isKz ? 'Кәсіпқой' : 'Профессионал';
  String get tierExpert => isKz ? 'Сарапшы' : 'Эксперт';
  String get tierGold => isKz ? 'Алтын Шебер' : 'Золотой Мастер';
  String get ordersToNextLevel => isKz ? 'тапсырыс келесі деңгейге' : 'заказов до следующего уровня';
  String get benefitSearch => isKz ? 'Іздеуде жоғары орын' : 'Выше в поиске';
  String get benefitVerified => isKz ? 'Тексерілген мастер' : 'Проверенный мастер';
  String get benefitRecommended => isKz ? 'Клиенттерге ұсынылады' : 'Рекомендован клиентам';
  String get benefitGold => isKz ? 'Алтын мәртебе + тегін жазылым' : 'Золотой статус + бесплатная подписка';

  // ── Notifications ─────────────────────────────────────────────
  String get notifTitle => isKz ? 'Хабарландырулар' : 'Уведомления';
  String get notifPush => isKz ? 'Push хабарландырулар' : 'Push-уведомления';
  String get notifPushSub => isKz ? 'Жаңа тапсырыстар туралы хабарлау' : 'Уведомлять о новых заказах';
  String get notifEmail => isKz ? 'Email хабарландырулар' : 'Email-уведомления';
  String get notifEmailSub => isKz ? 'Хаттар арқылы хабарлау' : 'Уведомлять через почту';

  // ── Auth email ────────────────────────────────────────────────
  String get emailTaken => isKz ? 'Бұл email бос емес' : 'Этот email уже занят';
  String get invalidEmailFormat => isKz ? 'Email форматы дұрыс емес' : 'Некорректный формат email';
  String get invalidCredentials => isKz ? 'Логин немесе пароль қате' : 'Неверный логин или пароль';
  String get passwordTooShort => isKz ? 'Пароль кемінде 6 таңба болуы керек' : 'Пароль должен быть не менее 6 символов';

  // ── Orders tabs ───────────────────────────────────────────────
  String get ordersTab => isKz ? 'Тапсырыстар' : 'Заказы';
  String get activeOrdersTab => isKz ? 'Белсенді' : 'Активные';
  String get completedOrdersTab => isKz ? 'Аяқталған' : 'Завершённые';
  String get noActiveOrders => isKz ? 'Белсенді тапсырыстар жоқ' : 'Нет активных заказов';
  String get noCompletedOrders => isKz ? 'Аяқталған тапсырыстар жоқ' : 'Нет завершённых заказов';

  // ── Master dashboard ──────────────────────────────────────────
  String get masterDashTitle => isKz ? 'Мастер кабинеті' : 'Кабинет мастера';
  String get availableOrders => isKz ? 'Қол жетімді тапсырыстар' : 'Доступные заказы';
  String get goToChat => isKz ? 'Чатқа өту' : 'Открыть чат';
  String get statNew => isKz ? 'Жаңа' : 'Новые';
  String get statActive => isKz ? 'Белсенді' : 'Активные';
  String get statDone => isKz ? 'Аяқталды' : 'Выполнено';

  // ── Snackbars ─────────────────────────────────────────────────
  String get switchToClientForOrder => isKz
      ? 'Тапсырыс жасау үшін клиент режиміне өтіңіз'
      : 'Переключитесь в режим клиента для создания заказа';

  // ── Error messages ────────────────────────────────────────────
  String get errNetworkTimeout => isKz ? 'Интернет байланысын тексеріңіз' : 'Проверьте подключение к интернету';
  String get errServerError => isKz ? 'Сервер қатесі. Кейінірек қайталаңыз.' : 'Ошибка сервера. Попробуйте позже.';
  String get errOrderMinBudget => isKz ? 'Ең төменгі бюджет — 500 ₸' : 'Минимальный бюджет — 500 ₸';
  String get errFillAllFields => isKz ? 'Барлық өрістерді толтырыңыз' : 'Заполните все поля';
  String get errPhoneInvalid => isKz ? 'Телефон нөмірі дұрыс емес' : 'Неверный номер телефона';
  String get errWrongCode => isKz ? 'Код дұрыс емес' : 'Неверный код';
  String get errCodeExpired => isKz ? 'Код мерзімі өтті' : 'Срок действия кода истёк';

  // ── Order statuses ────────────────────────────────────────────
  String get statusNew => isKz ? 'Жаңа' : 'Новый';
  String get statusInProgress => isKz ? 'Орындалуда' : 'В работе';
  String get statusCompleted => isKz ? 'Аяқталды' : 'Завершён';
  String get statusCancelled => isKz ? 'Болдырылмады' : 'Отменён';
  String orderStatus(String status) {
    switch (status) {
      case 'new': return statusNew;
      case 'in_progress': return statusInProgress;
      case 'completed': return statusCompleted;
      case 'cancelled': return statusCancelled;
      default: return status;
    }
  }

  // ── Order cancel ──────────────────────────────────────────────
  String get cancelOrderTitle => isKz ? 'Тапсырысты болдырмау' : 'Отменить заказ';
  String get cancelOrderConfirm => isKz ? 'Тапсырысты шынымен болдырмайсыз ба?' : 'Вы уверены, что хотите отменить заказ?';
  String get orderCancelledSuccess => isKz ? 'Тапсырыс болдырылмады' : 'Заказ отменён';

  // ── Order status timeline ─────────────────────────────────────
  String get orderTimeline => isKz ? 'Тапсырыс барысы' : 'Ход заказа';
  String get stepCreated => isKz ? 'Тапсырыс жасалды' : 'Заказ создан';
  String get stepAccepted => isKz ? 'Шебер қабылдады' : 'Мастер принял';
  String get stepCompleted => isKz ? 'Аяқталды' : 'Завершён';

  // ── Bidding (InDrive-style) ───────────────────────────────────
  String get bidTitle => isKz ? 'Баға ұсыну' : 'Предложить цену';
  String get bidClientPrice => isKz ? 'Клиент бюджеті' : 'Бюджет клиента';
  String get bidYourOffer => isKz ? 'Сіздің ұсынысыңыз' : 'Ваше предложение';
  String get bidCustomPrice => isKz ? 'Өз бағамды енгізу' : 'Ввести свою цену';
  String get bidSubmit => isKz ? 'Баға ұсыну →' : 'Предложить цену →';
  String get bidSubmitted => isKz ? 'Ұсыныс жіберілді!' : 'Предложение отправлено!';
  String get bidTooLow => isKz ? 'Баға тым төмен' : 'Цена слишком низкая';
  String get bidMinNote => isKz ? 'Ең төменгі баға' : 'Минимальная цена';
  String bidCount(int n) => isKz ? '$n ұсыныс' : '$n предложений';
  String get myBidLabel => isKz ? 'Менің ұсынысым' : 'Мой оффер';
  String get bidsTitle => isKz ? 'Шебер ұсыныстары' : 'Предложения мастеров';
  String get noBids => isKz ? 'Әлі ұсыныс жоқ' : 'Предложений пока нет';
  String get acceptBid => isKz ? 'Қабылдау' : 'Принять';
  String get rejectBid => isKz ? 'Бас тарту' : 'Отклонить';
  String get bidAccepted => isKz ? 'Ұсыныс қабылданды!' : 'Предложение принято!';
  String get bidRejected => isKz ? 'Ұсыныс қабылданбады' : 'Предложение отклонено';
  String get bidAlreadySent => isKz ? 'Ұсыныс жіберілді' : 'Оффер уже отправлен';
  String get filterByCategory => isKz ? 'Санат бойынша сүзу' : 'Фильтр по категории';

  // ── Report ────────────────────────────────────────────────────
  String get reportUser => isKz ? 'Шағым беру' : 'Пожаловаться';
  String get reportSent => isKz ? 'Шағым жіберілді' : 'Жалоба отправлена';
  String get reportReasonInappropriate => isKz ? 'Орынсыз мінез-құлық' : 'Неуместное поведение';
  String get reportReasonFraud => isKz ? 'Алдау / алаяқтық' : 'Обман / мошенничество';
  String get reportReasonNoShow => isKz ? 'Келмеді' : 'Не явился';
  String get reportReasonOther => isKz ? 'Басқа себеп' : 'Другая причина';
  String get reportReasonPick => isKz ? 'Себепті таңдаңыз' : 'Выберите причину';
  String get reportCommentHint =>
      isKz ? 'Толығырақ сипаттаңыз (міндетті емес)' : 'Опишите подробнее (необязательно)';
  String get reportSend => isKz ? 'Жіберу' : 'Отправить';
  String get reportClose => isKz ? 'Жабу' : 'Закрыть';
  String get reportSubmittedTitle => isKz ? 'Шағым қабылданды' : 'Жалоба принята';
  String get reportSubmittedBody =>
      isKz
          ? 'Сіздің шағымыңыз жіберілді.\nМодерация 24 сағат ішінде қарастырады.'
          : 'Ваша жалоба отправлена.\nМодерация рассмотрит её в течение 24 часов.';

  // ── Profile screen ────────────────────────────────────────────
  String get professionLabel => isKz ? 'Мамандық' : 'Профессия';
  String get changeProfession => isKz ? 'Мамандықты өзгерту' : 'Изменить профессию';
  String get notSet => isKz ? 'Белгіленбеген' : 'Не указано';
  String get yourCity => isKz ? 'Сіздің қалаңыз' : 'Ваш город';
  String get yourName => isKz ? 'Сіздің атыңыз' : 'Ваше имя';
  String get becomeClient => isKz ? 'Клиент болу' : 'Стать клиентом';
  String get becomeMaster => isKz ? 'Шебер болу' : 'Стать мастером';
  String get professionChanged => isKz ? 'Мамандық өзгертілді!' : 'Профессия изменена!';
  String get notAuthorized => isKz ? 'Авторизацияланбаған' : 'Не авторизован';
  String get searchingMaster => isKz ? 'Шебер ізделуде...' : 'Поиск мастера...';
  String get pickProfession => isKz ? 'Мамандықты таңдаңыз' : 'Выберите профессию';
  String get refreshOrders => isKz ? 'Тапсырыстарды жаңарту' : 'Обновить заказы';

  // ── Support chat ──────────────────────────────────────────────
  String get supportAutoReply =>
      isKz
          ? 'Хабарламаңыз жіберілді. Қолдау қызметі 24 сағат ішінде жауап береді.'
          : 'Ваше сообщение отправлено. Поддержка ответит в течение 24 часов.';
  String get supportResponseTime =>
      isKz ? 'Қолдау қызметі 24 сағат ішінде жауап береді' : 'Поддержка ответит в течение 24 часов';

  // ── Camera / Media picker ───────────────────────────────────
  String get cameraLabel => isKz ? 'Камера' : 'Камера';
  String get galleryLabel => isKz ? 'Галерея' : 'Галерея';
  String get photoUploadError => isKz ? 'Фото жүктеу қатесі' : 'Ошибка загрузки фото';

  // ── Connection / Errors ─────────────────────────────────────
  String get connectionError => isKz ? 'Байланыс қатесі. Кейінірек қайталаңыз.' : 'Ошибка связи. Попробуйте позже.';
  String get roleSelectError => isKz ? 'Рөл таңдау қатесі' : 'Ошибка выбора роли';

  // ── Profile fields ──────────────────────────────────────────
  String get phoneLabel => isKz ? 'Телефон' : 'Телефон';
  String get descriptionBioLabel => isKz ? 'Сипаттама (Bio)' : 'Описание (Bio)';
  String get experienceYearsLabel => isKz ? 'Тәжірибе (жыл)' : 'Опыт (лет)';

  // ── Subscriptions ───────────────────────────────────────────
  String get subscriptionTitle => isKz ? 'Жазылым' : 'Подписка';
  String get freePlan => isKz ? 'Тегін' : 'Бесплатный';
  String get premiumPlan => isKz ? 'Премиум' : 'Премиум';
  String get subscribeBuy => isKz ? 'Сатып алу' : 'Купить';
  String get subscribeCancel => isKz ? 'Жазылымды тоқтату' : 'Отменить подписку';
  String get subscribeResume => isKz ? 'Жазылымды жалғастыру' : 'Возобновить подписку';
  String get subscriptionActive => isKz ? 'Белсенді' : 'Активна';
  String get subscriptionExpired => isKz ? 'Мерзімі өтті' : 'Истекла';
  String get daysRemaining => isKz ? 'күн қалды' : 'дней осталось';
  String get balanceLabel => isKz ? 'Баланс' : 'Баланс';

  // ── City / Onboarding ───────────────────────────────────────
  String get chooseYourCity => isKz ? 'Қалаңызды таңдаңыз' : 'Выберите ваш город';
  String get citySelectOnboardingSub =>
      isKz
          ? 'Тапсырыстар мен шеберлер\nсіздің қалаңыз бойынша көрсетіледі'
          : 'Заказы и мастера\nпоказываются по вашему городу';
  String get continueBtn => isKz ? 'Жалғастыру' : 'Продолжить';
  String get whoAreYou => isKz ? 'Сіз кімсіз?' : 'Кто вы?';
  String get canChangeRoleLater => isKz ? 'Рөлді кейін өзгертуге болады' : 'Роль можно изменить позже';
  String get enterYourPhone => isKz ? 'Телефон нөміріңізді енгізіңіз' : 'Введите ваш номер телефона';
  String get getCode => isKz ? 'Код алу' : 'Получить код';

  // ── Master profile ─────────────────────────────────────────
  String get aboutMaster => isKz ? 'Өзі туралы' : 'О себе';
  String get portfolioEmpty => isKz ? 'Портфолио бос' : 'Портфолио пусто';
  String get addPhoto => isKz ? 'Фото қосу' : 'Добавить фото';
  String get noReviewsYet => isKz ? 'Пікірлер жоқ' : 'Отзывов пока нет';
  String get noCompletedWork => isKz ? 'Аяқталған жұмыстар жоқ' : 'Завершённых работ нет';
  String get tabPortfolio => isKz ? 'Портфолио' : 'Портфолио';
  String get tabReviewsShort => isKz ? 'Пікірлер' : 'Отзывы';
  String get tabWorkHistory => isKz ? 'Жұмыстар' : 'Работы';
  String get statRating => isKz ? 'Рейтинг' : 'Рейтинг';
  String get statJobsDone => isKz ? 'Жұмыс' : 'Работ';
  String get statReviewsShort => isKz ? 'Пікір' : 'Отзывов';
  String get statExperienceShort => isKz ? 'Тәжірибе' : 'Опыт';
  String get yearsShort => isKz ? 'ж' : 'л';
  String get memberSinceLabel => isKz ? 'Серіктес болғалы' : 'На платформе с';
  String get portfolioUploadSuccess => isKz ? 'Сәтті жүктелді' : 'Фото добавлено';
  String get masterDefaultName => isKz ? 'Шебер' : 'Мастер';

  // ── Login screen ────────────────────────────────────────────
  String get loginFreeFooter =>
      isKz ? 'Тіркелу қажет емес — кіру тегін' : 'Регистрация не нужна — вход бесплатный';
  String get loginFeatureFindMaster => isKz ? 'Шебер табу — тегін' : 'Поиск мастера — бесплатно';
  String get loginFeatureDirectContact => isKz ? 'Тікелей байланыс' : 'Прямая связь';
  String get loginFeatureRating => isKz ? 'Рейтинг және пікірлер' : 'Рейтинг и отзывы';
  String get errSendCodeFailed => isKz ? 'Код жіберу қатесі' : 'Ошибка отправки кода';
  String errorColonMessage(String msg) => isKz ? 'Қате: $msg' : 'Ошибка: $msg';

  // ── SMS code screen ─────────────────────────────────────────
  String codeSentToPhone(String phone) => isKz ? 'Код жіберілді: $phone' : 'Код отправлен: $phone';
  String get resendCode => isKz ? 'Кодты қайта жіберу' : 'Отправить код снова';
  String resendInSeconds(int sec) => isKz ? 'Қайта жіберу: $sec сек' : 'Повтор через $sec с';
  String get codeResentSuccess => isKz ? 'Код қайта жіберілді' : 'Код отправлен повторно';
  String get errWrongCodeTryAgain =>
      isKz ? 'Код дұрыс емес. Қайтадан көріңіз.' : 'Неверный код. Попробуйте снова.';
  String errResendFailed(String msg) =>
      isKz ? 'Код жіберілмеді: $msg' : 'Не удалось отправить код: $msg';

  // ── City picker sheet ───────────────────────────────────────
  String get cityPickerMastersSubtitle =>
      isKz ? 'Шеберлер қалаңызда көрсетіледі' : 'Мастера показываются для вашего города';
  String get citySearchHint => isKz ? 'Қала іздеу...' : 'Поиск города...';

  // ── Client home ─────────────────────────────────────────────
  String helloName(String name) => isKz ? 'Сәлем, $name!' : 'Привет, $name!';
  String get clientOrderTeaser =>
      isKz ? 'Мәселені сипаттаңыз — шебер келеді!' : 'Опишите проблему — мастер приедет!';

  // ── Role select cards ───────────────────────────────────────
  String get roleCardClientSubtitle => isKz ? 'Маған шебер керек' : 'Мне нужен мастер';
  String get roleCardMasterSubtitle => isKz ? 'Мен жұмыс орындаймын' : 'Я выполняю работы';

  // ── Profile edit / avatar ───────────────────────────────────
  String yearsExperience(int y) => isKz ? '$y жыл' : '$y лет';
  String get profileEditBioShort => isKz ? 'Сипаттама' : 'Описание';
  String get profileBioEditHint =>
      isKz ? 'Өзіңіз туралы қысқаша жазыңыз...' : 'Кратко о себе...';
  String get profileExpEditHint => isKz ? 'Мысалы: 5' : 'Например: 5';
  String get profileCityEditHint => isKz ? 'Қызылорда, Алматы...' : 'Кызылорда, Алматы...';
  String get avatarUpdated => isKz ? 'Фото жаңартылды ✓' : 'Фото обновлено ✓';
  String get profileTapChangePhoto =>
      isKz ? 'Фото өзгерту' : 'Сменить фото';
  String get editProfilePortfolioHint =>
      isKz ? 'Жұмыстарыңыздың фотосын қосыңыз (12-ге дейін)' : 'До 12 фото ваших работ';

  // ── Home tab / support menu ─────────────────────────────────
  String get supportServiceMenu => isKz ? 'Қолдау қызметі' : 'Служба поддержки';
  String get bannerPartnerStoreTitle => 'GIBADAT_KZO';
  String get bannerPartnerStoreSubtitle =>
      isKz ? 'GIBADAT дүкені — 15% жеңілдік' : 'магазин GIBADAT — скидка 15%';
  String get bannerPremiumTitle => 'Sheber Premium';
  /// Без «30 күн тегін» — клиенттерді шошытпау үшін.
  String get bannerPremiumSubtitle =>
      isKz
          ? 'Мастерлерге кеңейтілген мүмкіндіктер'
          : 'Расширенные возможности для мастеров';
  String get bannerAdSlotTitle => isKz ? 'Жарнама орны' : 'Место для рекламы';
  String get bannerAdSlotSubtitle =>
      isKz ? 'Мұнда сіздің жарнамаңыз!' : 'Здесь может быть ваша реклама!';
  String get advertiseDialogTitle => isKz ? 'Жарнама орналастыру' : 'Размещение рекламы';
  String get advertiseDialogBody => isKz
      ? 'Sheber.kz-те жарнама орналастыру үшін бізге хабарласыңыз:\n\nWhatsApp: +7 702 830 1616\nEmail: militechcampus@gmail.com'
      : 'Для размещения рекламы на Sheber.kz свяжитесь с нами:\n\nWhatsApp: +7 702 830 1616\nEmail: militechcampus@gmail.com';
  String get whatsappLabel => 'WhatsApp';

  // ── Subscription screen ─────────────────────────────────────
  String get subTrialPeriod => isKz ? 'Бастапқы кезең' : 'Стартовый период';
  String get subPremiumActiveLabel => isKz ? 'Premium белсенді' : 'Premium активен';
  String subTrialUntilDays(String dateLabel, int days) =>
      isKz ? '$dateLabel дейін • $days күн қалды' : 'До $dateLabel • осталось $days дн.';
  String subDaysLeftLine(int days) => isKz ? '$days күн қалды' : 'Осталось $days дней';
  String get subFreeTierPitch =>
      isKz
          ? 'Қазіргі тариф: Free. Толық мүмкіндіктер тізімі төменде.'
          : 'Текущий тариф: Free. Сравнение возможностей ниже.';
  String get subFeatLast10Orders => isKz ? 'Соңғы 10 тапсырыс' : 'Последние 10 заказов';
  String get subFeat5OrdersMonth => isKz ? 'Айына 5 тапсырыс қабылдау' : '5 заказов в месяц';
  String get subFeatEditReview => isKz ? 'Пікір өзгерту' : 'Редактировать отзыв';
  String get subFeatEditReview3d => isKz ? 'Пікір өзгерту (3 күн)' : 'Редактировать отзыв (3 дня)';
  String get subFeatVerifiedBadge => isKz ? '"Тексерілген" белгі' : 'Значок «Проверен»';
  String get subFeatHigherSearch => isKz ? 'Іздеуде жоғарыда' : 'Выше в поиске';
  String get subFeatAllOrders => isKz ? 'Барлық тапсырыстар' : 'Все заказы';
  String get subFeatUnlimitedOrders => isKz ? 'Шексіз қабылдау' : 'Безлимит заказов';
  /// Төлемді әлі қоспаған кезде — Kaspi қадамдарын орнына.
  String get subBillingPauseNote =>
      isKz
          ? 'Қазір автоматты төлем қосылмаған. Сұрақтар болса, қолдау қызметіне жазыңыз.'
          : 'Автооплата пока не подключена. По вопросам обратитесь в поддержку.';
  String get subPriceMonthly => isKz ? '2 990 ₸/ай' : '2 990 ₸/мес';
  String get tierPremiumLabel => 'Premium';
  String get tierFreeLabel => 'Free';
  String get subStatusActiveShort => isKz ? 'Белсенді' : 'Активен';
}
