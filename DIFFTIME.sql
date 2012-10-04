
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[DIFFTIME]') and xtype in (N'FN', N'IF', N'TF'))
	drop function DIFFTIME
go

/*
	Obtiene el tiempo trabajado, en segundos, entre dos fechas
	PARAMETROS:
		@start_date: fecha de inicio
		@end_date: fecha de fin
	Ej: select dbo.DIFFTIME('20120712 12:30:00','20120714 15:00:00')/60.0/60.0
	
*/

create function DIFFTIME(@start_date as datetime, @end_date as datetime)  
returns integer
as
BEGIN

declare @ttr_calendar as  TABLE(
	[day_number] [varchar] (50) NOT NULL ,
	[day_name] [varchar] (50) NULL ,
	[begin_time] [datetime] NULL ,
	[end_time] [datetime] NULL ,
	[duration] [real] NULL 
)

--Horario de trabajo considerado para hacer el cálculos de tiempo trabajado
insert into @ttr_calendar
select 1,             'Monday',      '7:30:00 AM',    '7:30:00 PM',   null union all
select 2,             'Tuesday',     '7:30:00 AM',    '7:30:00 PM',   null union all
select 3,             'Wednesday',   '7:30:00 AM',    '7:30:00 PM',   null union all
select 4,             'Thursday',    '7:30:00 AM',    '7:30:00 PM',   null union all
select 5,             'Friday',      '7:30:00 AM',    '7:30:00 PM',   null --union all
--select 6,             'Saturday',    '8:00:00 AM',    '5:00:00 PM',   null union all
--select 7,             'Sunday',      '8:00:00 AM',    '5:00:00 PM',   null

update @ttr_calendar set [duration]=DATEDIFF(ss,begin_time,end_time)

declare @total_time as integer

select @total_time  = sum(
	case
		--Se verifica si ambas fechas inicio y fin pertenecen al mismo día (sin considerar hora). 
		--dateadd(day, datediff(day, 0, @start_date), 0): obtiene la fecha sin hora
		when dateadd(day, datediff(day, 0, @start_date), 0) = dateadd(day, datediff(day, 0, @end_date), 0) then  
			datediff(second, @start_date, @end_date)
		when d.[DATE] = dateadd(day, datediff(day, 0, @start_date), 0) then  
			case
				when @start_date < d.[DATE] + begin_time then duration
				when @start_date > d.[DATE] + end_time then 0
				else datediff(second, @start_date, d.[DATE] + end_time)  
			end  
		when d.[DATE] = dateadd(day, datediff(day, 0, @end_date), 0) then  
			case
				when @end_date > d.[DATE] + end_time then duration
				when @end_date < d.[DATE] + begin_time then 0
				else datediff(second, d.[DATE] + begin_time, @end_date)  
			end  
		else duration  
	end  
     )	
from F_TABLE_DATE(@start_date, @end_date) d inner join @ttr_calendar c
	on	d.WEEKDAY_NAME_LONG = c.day_name
where dbo.ES_FERIADO(d.[DATE])=0

return isnull(@total_time,0)

END