Rickshaw
========

Rickshaw is small but full-featured client-side MVC framework using (and
adhering to the idioms of) [MooTools][mootools] for models and controllers and
[Handlebars][handlebars] for templating (views).

[Documentation][docs] (in progress, already out of date)

Rickshaw depends on a [subset of MooTools][mootools_subset]

[mootools]: http://mootools.net
[handlebars]: http://handlebarsjs.com/
[docs]: http://tysontate.github.com/Rickshaw/
[mootools_subset]: http://mootools.net/core/65113033d87e7b864acdfd4d3585b261

General Philosophy
------------------

MooTools is great, JavaScript is good, and boilerplate is bad.

To do
-----

(Roughly in order of importance)

* Specs for:
  * ListController
    * Lots of spec fun to be had with the list item subcontrollers + event delegation, and so on.
  * Handlebars extensions
* Make ListController re-rendering more efficient when sorting or reversing the list
* Some sort of pluggable persistance backend
  * RESTful, WebSockets, LocalStorage, etc.
  * Should make it easy to define your own and subclass them, especially for
    WebSockets if you want to implement your own message protocol.
* Auto-updating selector bindings
  * If I add an event on "div.rad" and that "rad" class is bound, the events
    should automatically be removed. I think the solution here is to wrap all
    added events with a function that re-checks for selector match before
    firing. Or: delegated events on enforced parent elements.
* Form bindings
  * You should be able to make create / edit forms super easily and never
    have to worry about maintaining bindings / events
* Better model change bindings
  * Ember.js-style might be overly ambitious / heavy, but it's worth
    investigation
* Get specs running in command-line, too
  * See https://github.com/logicalparadox/chai-spies for info

Misc:

* Do we want to store parent views on subcontrollers / subviews?

Development
-----------

To watch source files for changes and recompile to `public/rickshaw.js`:

    > bundle install
    > bundle exec guard

I'm using Growl for notifications. If you want Growl notifications for the
build, [download and install GrowlNotify](http://growl.info/downloads#generaldownloads).

You don't need to watch for changes while testing. Coffeeshop will automatically pick up the changes.

Tests
-----

Install [coffeeshop](https://github.com/tysontate/coffeeshop):

    > bundle install

Run coffeeshop to serve up the files:

    > coffeeshop
    > open "http://localhost:4567/test"
