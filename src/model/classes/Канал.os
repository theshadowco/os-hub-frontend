&Идентификатор
&ГенерируемоеЗначение
&Колонка(Тип = "Целое")
Перем Код Экспорт;

Перем Имя Экспорт;

Перем Каталог Экспорт;

Перем Описание Экспорт;

&Сущность(ИмяТаблицы = "Каналы")
Процедура ПриСозданииОбъекта()

КонецПроцедуры

Процедура Сохранить() Экспорт
	МенеджерБазыДанных.МенеджерСущностей.Сохранить(ЭтотОбъект);
КонецПроцедуры