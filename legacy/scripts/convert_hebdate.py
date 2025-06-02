from pyluach import dates
import datetime
 
# קבלת התאריך הלועזי הנוכחי
today_gregorian = datetime.date.today()
 
# המרת התאריך הלועזי לתאריך עברי
hebrew_date = dates.GregorianDate(today_gregorian.year, today_gregorian.month, today_gregorian.day).to_heb()
 
# הצגת התאריך העברי בפורמט עברי
hebrew_date_str = hebrew_date.hebrew_date_string()
print(f"התאריך העברי היום הוא: {hebrew_date_str}")