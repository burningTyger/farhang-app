#Farhang

Farhang is a dictionary app written in Ruby with Sinatra and MongoDB.

It is not a dictionary itself but a nice and simple interface to a dictionary
stored in a database.

![Farhang.im in action](http://d.pr/i/W1JY+)
See it in action with the original German-Persian dictionary at
https://www.farhang.im

If you have a dictionary that has unique word entries along with
translations and possibly examples there are good chances you will be
able to make it available to Farhang (see the German-Persian language files
on their [GitHub repo](https://github.com/ckh/farhang) for comparison).

    stellen;
    - die Uhr stellen; ساعَت را میزان کَردَن
    - Wecker stellen; ساعَت ِ شُماطه را تَنظیم کَردَن
    - zur Diskussion stellen; به بَحث گُذاشتَن
    - jem. auf die Beine stellen; کِسى را روى ِ پا ایستاندَن، ـ ایستانیدَن
    - jem. ein Bein stellen; کَله پائىن کَردَن
    - jem. vor vollendete Tatsachen stellen; دَر بَرابَر ِ اَمر ِ واقِع قَرار دادَن
    - etwas an seinen Platz stellen; چیزى را سَر ِ جايَش گُذاشتَن
    - etwas über eine andere Sache stellen; چیزى را از چیزى ِ دیگَر مُهِمتَر تَلَقى کَردَن
    - s. der Verantwortung stellen; وَظیفه را به خود اِختِصاص دادَن
    - s. schlafend stellen; خودرا به خواب زَدَن
    - s. unglücklich stellen; خودرا موش مَرگى زَدَن
    - s. unwissend stellen; خودرا به نَدانِستَن زَدَن
    - s. der Polizei stellen; خودرا به پُلیس مُعَرِفى کَردَن
    - ihr wurdet an ihren Platz gestellt; شُما سَر ِ جاى ِ آنها قَرار گِرِفتید
    - auf s. gestellt sein; از هَمه تَرک گُفته، تَک و تَنها بودَن

In the above example you can see a _lemma_ which is the first line and two
examples that start with a _dash_. Translations are separated by a _semicolon_.

Farhang expects a Mongo Document which stores the _lemma_ as a unique
key and embeds all examples and their translations as Embedded
Documents.

So if you happen to have a dictionary that has a common separator for
its entries you might want to check out the [Farhang
Converter](https://github.com/burningTyger/farhang-txt2mongo) to see if
you can adapt it to your needs.

##Features
Farhang is super lighweight and runs with few dependencies. It's written with
Sinatra and MongoDB for super fast access.

Farhang has some nice built-in features you wouldn't want to miss in
your dictionary app:

* User management with three roles: root, admin and user.
  * Users can add entries
  * Admins can verify user entries
  * root is the site owner and can manage users and site settings
* simple site management like adding keywords or analytics

##Requirements
It runs on MRI, JRuby and Rubinius in 1.9 mode.

You need a running MongoDB and your own `config.rb`. Make sure to rename
`config-example.rb` to `config.rb` and use your own values.

It works best if you clone it with git:

    git clone git://github.com/burningTyger/farhang-app.git

Then you fire up your instance of Farhang via:

    ruby farhang.rb

This will start your server and your app. Usually the local address to
see Farhang in your browser is http://localhost:4567 if you prefer
other port numbers you can use the `-p` option:

    ruby farhang.rb -p 9393

Usually this will start up webrick which I find intolerably slow, so I
prefer newer servers like [thin](https://github.com/macournoyer/thin) or
[puma](http://puma.io/) which can be installed like this:

    gem install puma

If you want to deploy it on some PAAS I can highly recommend Red Hat's
[Openshift](https://openshift.redhat.com/app/). They give you lots of
space for your app and your database and don't charge a cent up to a
certain limit. Ideal for noncommercial dictionaries.

Heroku is also fine but has limitations with the database. You will need
to provide your own or try [mongolab](https://mongolab.com) who offer
500MB for free which should be enough for a dictionary.

##Notes
Feel free to fork this repository or the dictionary, MIT and CC licensed.
