root: @countries(num), @languages(num), @scripts(num), population
--
[regions or countries]*: (countries), population, languages, scripts

lang: speakers, scripts, countries



world (@c, @l, @s, p, regions*)
  europe (@c, @l, p, r*)
    south (@l, p, c*)
      italia ((@l,p)*)
  countries4region (), ordered by population
  langs4region (), ordered by speakers
    lang (speakers, s*, c*)
  scripts 
    script (letters, l*)


--------

https://github.com/felixblaschke/simple_animations
https://pub.dev/documentation/locales/latest/locales/Locale-class.html#constants 
