
Перем КоллекцияКаналов;
Перем ПакетыХаба;
Перем ВерсииПакетовХаба;

Функция ЗапуститьИмпортВБД() Экспорт
	
	Результат = Истина;
	
	// не мигрируем данные, если есть записи в таблице Пакеты
	КоллекцияПакеты = МенеджерБазыДанных.ПакетыМенеджер.Получить();
	Если КоллекцияПакеты.Количество() > 0 Тогда
		Возврат Результат;
	КонецЕсли;
	
	ОчиститьБазуДанных();
	ПодготовитьДанные();
	ЗагрузитьДанные();
	
	Возврат Результат;
	
КонецФункции

Процедура ПодготовитьДанные()
	
	ПакетыХаба = Новый ТаблицаЗначений;
	ПакетыХаба.Колонки.Добавить("Имя");
	ПакетыХаба.Колонки.Добавить("Описание");
	ПакетыХаба.Колонки.Добавить("Путь");
	ПакетыХаба.Колонки.Добавить("Автор");
	ПакетыХаба.Колонки.Добавить("КлючевыеСлова");
	ПакетыХаба.Колонки.Добавить("ПутьКОписанию");
	ПакетыХаба.Колонки.Добавить("Проект");
	ПакетыХаба.Колонки.Добавить("АктуальнаяВерсия");
	
	ВерсииПакетовХаба = Новый ТаблицаЗначений;
	ВерсииПакетовХаба.Колонки.Добавить("Имя");
	ВерсииПакетовХаба.Колонки.Добавить("Канал");
	ВерсииПакетовХаба.Колонки.Добавить("Версия");
	ВерсииПакетовХаба.Колонки.Добавить("Путь");
	ВерсииПакетовХаба.Колонки.Добавить("Зависимости");
	
	КаталогХаба = ПереченьПакетов.КаталогХраненияПакетов();
	
	КоллекцияКаналов = Новый Массив;
	КоллекцияКаналов.Добавить("download"); // релиз
	КоллекцияКаналов.Добавить("dev-channel"); // разработка
	
	СписокПакетов = Новый Массив;
	Для Каждого Канал Из КоллекцияКаналов Цикл	
		ЭлементыКаталога = НайтиФайлы(ОбъединитьПути(КаталогХаба, Канал), "*");
		Для Каждого ЭлементКаталога Из ЭлементыКаталога Цикл
			Если ЭлементКаталога.ЭтоКаталог() Тогда
				Если СписокПакетов.Найти(ЭлементКаталога.Имя) = Неопределено Тогда
					СписокПакетов.Добавить(ЭлементКаталога.Имя);
					НовыйПакет = ПакетыХаба.Добавить();
					
					НовыйПакет.Имя = ЭлементКаталога.Имя;
					НовыйПакет.Путь = ОбъединитьПути(Канал, НовыйПакет.Имя);
				КонецЕсли;
			КонецЕсли;
		КонецЦикла;
	КонецЦикла;
	
	Для Каждого Пакет Из ПакетыХаба Цикл
		
		ПутьКМетаданным = ОбъединитьПути(КаталогХаба, Пакет.Путь, "meta.json");
		Попытка
			МетаОписание = ОбщегоНазначения.ПрочитатьJSON(ПутьКМетаданным);
		Исключение
			МетаОписание = Неопределено;
			Сообщить("Не удалось получить / прочитать meta.json пакета " + Пакет.Имя + ". Причина: " + ОписаниеОшибки());
		КонецПопытки;
		
		Если МетаОписание <> Неопределено Тогда
			Пакет.Описание = МетаОписание.Получить("Описание");
			Пакет.Автор = МетаОписание.Получить("Автор");
			Пакет.КлючевыеСлова = МетаОписание.Получить("КлючевыеСлова");
			Пакет.Проект = МетаОписание.Получить("АдресРепозитория");
			
			Пакет.АктуальнаяВерсия = МетаОписание.Получить("АктуальнаяВерсия");
		КонецЕсли;
		
		Для Каждого Канал Из КоллекцияКаналов Цикл
			
			КаталогПакета = ОбъединитьПути(КаталогХаба, Канал, Пакет.Имя);
			Файлы = НайтиФайлы(КаталогПакета, "*-*.ospx");
			
			Для Каждого Файл Из Файлы Цикл
				
				НоваяВерсия = ВерсииПакетовХаба.Добавить();
				НоваяВерсия.Имя = Пакет.Имя;
				НоваяВерсия.Канал = Канал;
				НоваяВерсия.Версия = ВерсияИзИмениФайла(НРег(Файл.ИмяБезРасширения), НРег(НоваяВерсия.Имя));
				НоваяВерсия.Путь = ОбъединитьПути(НоваяВерсия.Канал, НоваяВерсия.Имя, Файл.Имя);
				НоваяВерсия.Зависимости = ПрочитатьЗависимостиПакета(Файл.ПолноеИмя);
				
			КонецЦикла;
			
			Если Канал = "download" Тогда
				
				ПутьКОписанию = ОбъединитьПути(Канал, Пакет.Имя, "readme.md");
				ФайлОписания = Новый Файл(ОбъединитьПути(КаталогХаба, ПутьКОписанию));
				Если ФайлОписания.Существует() Тогда
					Пакет.ПутьКОписанию = ПутьКОписанию;
				КонецЕсли;
				
			КонецЕсли;
			
		КонецЦикла;
		
	КонецЦикла;
	
КонецПроцедуры

Процедура ЗагрузитьДанные()
	
	КаналРелиз = Новый Канал();
	КаналРелиз.Имя = "stable";
	КаналРелиз.Каталог = "download";
	КаналРелиз.Сохранить();
	
	КаналРазработка = Новый Канал();
	КаналРазработка.Имя = "develop";
	КаналРазработка.Каталог = "dev-channel";
	КаналРазработка.Сохранить();
	
	СписокКаналов = Новый Массив;
	СписокКаналов.Добавить(КаналРелиз);
	СписокКаналов.Добавить(КаналРазработка);
	
	Для Каждого СтрокаПакет Из ПакетыХаба Цикл
		
		Пакет = Новый Пакет();
		Пакет.Код = СтрокаПакет.Имя; 
		Пакет.Наименование = Пакет.Код;
		
		Если ЗначениеЗаполнено(СтрокаПакет.Автор) Тогда
			Пакет.Автор = ПолучитьСоздатьАвтора(СтрокаПакет.Автор);
		КонецЕсли;
		
		Пакет.Описание = СтрокаПакет.Описание;
		Пакет.КлючевыеСлова = СтрокаПакет.КлючевыеСлова;
		Пакет.СсылкаНаПроект = СтрокаПакет.Проект;
		Пакет.ПутьКОписанию = СтрокаПакет.ПутьКОписанию;
		Пакет.Сохранить();
		
		Для Каждого Канал Из СписокКаналов Цикл
			
			РезультатПоискаВерсий = ВерсииПакетовХаба.НайтиСтроки(Новый Структура("Канал, Имя", Канал.Каталог, Пакет.Код));
			Если РезультатПоискаВерсий.Количество() = 0 Тогда
				Продолжить;
			КонецЕсли;
			
			ПакетКанала = Новый ПакетКанала();
			ПакетКанала.Пакет = Пакет.Код;
			ПакетКанала.Путь = ОбъединитьПути(Канал.Каталог, ПакетКанала.Пакет);
			ПакетКанала.Канал = Канал;
			Если Канал = КаналРелиз Тогда
				ПакетКанала.АктуальнаяВерсия = СтрокаПакет.АктуальнаяВерсия;
			КонецЕсли;
			ПакетКанала.ДатаСоздания = ТекущаяДата();
			ПакетКанала.ДатаОбновления = ПакетКанала.ДатаСоздания;
			ПакетКанала.Сохранить(); 
			
			Для Каждого СтрокаВерсии Из РезультатПоискаВерсий Цикл
				
				ВерсияПакета = Новый ВерсияПакета();
				ВерсияПакета.Номер = СтрокаВерсии.Версия;
				ВерсияПакета.Пакет = Пакет.Код;
				ВерсияПакета.ПакетКанала = ПакетКанала.Код;
				ВерсияПакета.Путь = СтрокаВерсии.Путь;
				ВерсияПакета.Канал = Канал.Код;
				ВерсияПакета.Зависимости = ЗависимостиВерсииПакета(СтрокаВерсии.Зависимости);
				
				ВерсияПакета.ДатаСоздания = ПакетКанала.ДатаСоздания;
				ВерсияПакета.ДатаОбновления = ПакетКанала.ДатаОбновления;
				
				ВерсияПакета.Сохранить();
				
			КонецЦикла;
			
			Если Канал = КаналРазработка Тогда
				
				// вычислим максимальную версию
				ПакетКанала.АктуальнаяВерсия = АктуальнаяВерсияПакетаИзКанала(Пакет.Код, ПакетКанала);
				ПакетКанала.Сохранить();
				
			КонецЕсли;
			
			
		КонецЦикла;
		
	КонецЦикла;
	
КонецПроцедуры

Функция АктуальнаяВерсияПакетаИзКанала(Пакет, ПакетКанала) Экспорт
	
	// выполним произвольный запрос
	Результат = Неопределено;

	Отбор = Новый Соответствие;
	Отбор.Вставить("ПакетКанала", ПакетКанала.Код); // TODO: хотелось бы ПакетКанала = ПакетКанала
	РезультатПоиска = МенеджерБазыДанных.МенеджерСущностей.Получить(Тип("ВерсияПакета"), Отбор);

	МассивВерсий = Новый Массив;
	Для Каждого Строка Из РезультатПоиска Цикл
		МассивВерсий.Добавить(Строка.Номер);
	КонецЦикла;

	// отсортировать по возврастанию
	Попытка	
		СортировкаВерсий.СортироватьВерсии(МассивВерсий, "Возр");
	Исключение
		Сообщить("Не удалось отсортировать версии пакета " + Пакет);
		Возврат Неопределено;
	КонецПопытки;
	
	// берем последнюю
	Если МассивВерсий.Количество() > 0 Тогда
		Результат = МассивВерсий[МассивВерсий.ВГраница()];
	КонецЕсли;

	Возврат Результат;
	
КонецФункции

Функция ЗависимостиВерсииПакета(Зависимости) Экспорт
	
	Массив = Новый Массив;
	
	Для Каждого СтрокаЗависимость Из Зависимости Цикл
		
		Зависимость = Новый Зависимость();
		Зависимость.Пакет = СтрокаЗависимость.Пакет;
		Зависимость.Версия = СтрокаЗависимость.Версия;
		Зависимость.МаксимальнаяВерсия = СтрокаЗависимость.МаксимальнаяВерсия; 
		Зависимость.Сохранить();
		
		Массив.Добавить(Зависимость);
		
	КонецЦикла;
	
	Возврат Массив;
	
КонецФункции

Процедура ОчиститьБазуДанных()
	
	Сообщить("Очистка базы данных");
	МенеджерБазыДанных.МенеджерСущностей.ПолучитьКоннектор().ВыполнитьЗапрос("DELETE FROM ВерсияПакета_Зависимости");
	ОчиститьТаблицуСущности("ВерсияПакета");
	ОчиститьТаблицуСущности("Зависимость");
	ОчиститьТаблицуСущности("ПакетКанала");
	ОчиститьТаблицуСущности("Пакет");
	ОчиститьТаблицуСущности("Автор");
	ОчиститьТаблицуСущности("Канал");
	
КонецПроцедуры

Функция ВерсияИзИмениФайла(ИмяФайла, Пакет)
	
	Возврат СтрЗаменить(ИмяФайла, Пакет + "-", "");
	
КонецФункции

Процедура ОчиститьТаблицуСущности(Тип)
	
	Коллекция = МенеджерБазыДанных.МенеджерСущностей.Получить(Тип(Тип));
	Для Каждого ЭлементКоллекции Из Коллекция Цикл
		МенеджерБазыДанных.МенеджерСущностей.Удалить(ЭлементКоллекции);	
	КонецЦикла;
	
КонецПроцедуры

Функция ПрочитатьЗависимостиПакета(ИмяФайла) Экспорт
	
	КоллекцияЭлементов = Новый Массив;
	Архив = Новый ЧтениеZipФайла();
	Попытка
		Архив.Открыть(ИмяФайла,, КодировкаИменФайловВZipФайле.UTF8);
	Исключение
		Сообщить(ИмяФайла);
		Сообщить(ОписаниеОшибки());
		Возврат Новый Массив;
	КонецПопытки;
	ЭлементМанифеста = Архив.Элементы.Найти("opm-metadata.xml");
	Если ЭлементМанифеста = Неопределено Тогда
		Возврат КоллекцияЭлементов;
	КонецЕсли;
	
	ВременныйКаталог = ПолучитьИмяВременногоФайла();
	Архив.Извлечь(ЭлементМанифеста, ВременныйКаталог);
	Архив.Закрыть();
	
	ПутьКМетаданным = ОбъединитьПути(ВременныйКаталог, "opm-metadata.xml");
	
	Чтение = Новый ЧтениеXML();
	Попытка
		Чтение.ОткрытьФайл(ПутьКМетаданным);
		Пока Чтение.Прочитать() Цикл
			Если Чтение.ТипУзла = ТипУзлаXML.НачалоЭлемента И Чтение.Имя = "depends-on" Тогда
				Зависимость = Новый Структура("Пакет, Версия, МаксимальнаяВерсия");
				Зависимость.Пакет = Чтение.ЗначениеАтрибута("name");
				Зависимость.Версия = Чтение.ЗначениеАтрибута("version");
				Если Не ЗначениеЗаполнено(Зависимость.Версия) Тогда
					Зависимость.Версия = "0";
				КонецЕсли;
				Зависимость.МаксимальнаяВерсия = "999";
				
				КоллекцияЭлементов.Добавить(Зависимость);
			КонецЕсли;
		КонецЦикла;
	Исключение
		Сообщить("Не удалось прочитать метаданные " + ИмяФайла);
	КонецПопытки;
	Чтение.Закрыть();
	
	Попытка
		УдалитьФайлы(ВременныйКаталог);
	Исключение
		Сообщить("Не удалось удалить временный каталог: " + ВременныйКаталог);
	КонецПопытки;
	
	Возврат КоллекцияЭлементов;
	
КонецФункции

Функция ПолучитьСоздатьАвтора(ИмяАвтора) Экспорт
	
	Если Не ЗначениеЗаполнено(ИмяАвтора) Тогда
		Возврат Неопределено;
	КонецЕсли;
	
	// todo: Переделать!
	МенеджерАвторов = Новый Автор();
	Автор = МенеджерАвторов.НайтиАвтораПоИмени(МенеджерБазыДанных.МенеджерСущностей, ИмяАвтора);
	Если Автор = Неопределено Тогда
		Автор = Новый Автор();
	КонецЕсли;
	Автор.Имя = ИмяАвтора;
	Автор.Сохранить();
	
	Возврат Автор;
	
КонецФункции