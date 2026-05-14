/// Inspiring Islamic and productivity quotes for Amal Tracker.
class AppQuotes {
  AppQuotes._();

  static const List<String> quotes = [
    'The most beloved of deeds to Allah are those that are most consistent, even if they are small.',
    'Whoever takes a path in search of knowledge, Allah will make easy for him the path to Paradise.',
    'Be in this world as if you were a stranger or a traveler on a road.',
    'Take advantage of five matters before five other matters: your youth, health, wealth, leisure, and life.',
    'Purity is half of faith.',
    'Truthfulness leads to righteousness, and righteousness leads to Paradise.',
    'The strong man is not the one who can wrestle, but the one who can control himself when angry.',
    'Allah does not look at your forms or your wealth, but He looks at your hearts and your deeds.',
    'The best among you are those who are best to their families.',
    'Every act of goodness is charity.',
    'A Muslim is a brother of another Muslim.',
    'He who believes in Allah and the Last Day should honor his guest.',
    'Modesty is part of faith.',
    'The key to Paradise is prayer.',
    'A kind word is a form of charity.',
    'Your smile for your brother is a form of charity.',
    'Cleanliness is part of faith.',
    'The most excellent Jihad is that for the conquest of self.',
    'Keep your tongue moist with the remembrance of Allah.',
    'Verily, with hardship comes ease.',
    'Success is not final, failure is not fatal: it is the courage to continue that counts.',
    'The only way to do great work is to love what you do.',
    'Start where you are. Use what you have. Do what you can.',
    "Don't count the days, make the days count.",
    'Small progress is still progress.',
    'Discipline is choosing between what you want now and what you want most.',
    'Patience is the key to all relief.',
    'Gratefulness brings abundance.',
    'Focus on being productive instead of busy.',
    'Your life is a reflection of your habits.'
  ];

  static String getQuoteOfTheDay() {
    final now = DateTime.now();
    // Use day of year to get a consistent quote for the day
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    return quotes[dayOfYear % quotes.length];
  }
}
