# TODO Ideas

## Please Note
These are just brainstorming ideas and the mere inclusion of items on the list does not mean they automatically are cleared for implementation in the specific way described here. It is recommended anything large should be first discussed on [IRC](irc://irc.freenode.net/perl6) or [in a GitHub Issue](https://github.com/perl6/modules.perl6.org/issues/), lest the implementation effort is wasted if the large part of the community has a different point of view.

## Koalatee
### Status of the implementation

Removed.

### Description
The old site contained badges, like `has_readme`, `has_tests`, `panda spec conformance`, etc. More badges were being suggested, such as [POD Coverage](https://github.com/teodozjan/pod6-coverage/). Since 99% of the dists had all the badges and adding new badges would call for more precious screen real estate, it is proposed to merge all of those metrics into two numbers called *Koalatee*. They will range from `0` to `100` percent.

The first number will include *Koalatee* metrics the necessity of conformance to which is widely accepted, are achievable for most dists, and automated tests for which have sturdy implementation (the readme, tests, spec badges would fall into that). The second number will include "experimental" *Koalatee* metrics that don't fall into the first category. Currently, `POD::Coverage` metric will be included here, since the `POD::Coverage` module is still on the experimental side of things and it is not yet clear how many false positives it will identify. So as not to upset the authors by lowering their "standard" (or call it "core") *Koalatee*, only the experimental metric might be lowered instead.

The *Koalatee* numbers will be displayed on the dists list page and clicking the Koalatee number will lead to the more detailed page for that dist where issues, if any, could be inspected and explained, so the authors could address them. The ranking of dists/authors by *Koalatee* could also be made into a sort of a game, where authors compete against each other by improving their dists to attain higher *Koalatee* scores.

There is a successful implementation of this idea in other languages, such as Perl 5. [Here](http://cpants.cpanauthors.org/dist/Imager-Tiler) is the example of viewing metrics for a single dist. [Here](http://cpants.cpanauthors.org/author/ZOFFIX) is the page showing *Koalatee* metrics for all the dists of a single author in a concise table. And [here](http://cpants.cpanauthors.org/ranking/five_or_more) is the aforementioned game; note how the authors do not lose any points if their experimental metrics are failing.

## Dist Information
### Status of the implementation
No code yet, other than `/dist/:dist` route defined that currently simply redirects to the
dist's GitHub repo.

### Description
The current way we display dists is to just list the main module. The dists info page would allow users to click on a dist in the list and view more detailed information, which can include:

* Dependencies
* List of modules in the distribution
* Standardized documentation
* [Test results](https://github.com/perl6/modules.perl6.org/issues/10)
* User Reviews

The standardized documentation would likely be very beneficial, considering dists have a variety of ways to include documentation. Some include it as embedded POD intertwined with code, and it's very difficult to read it on GitHub (i.e. without installing the module).

## Dist Karma
### Status of the implementation
No code yet.

#### Description
This likely could be merged or tied to `Dist Reviews` feature. The idea is that you can increase or decrease dist's "karma" by clicking a button. This assumes we have some sort of login implemented (likely a "log in via GitHub" feature; see `Authority Information` feature proposal below). The higher the karma the more people liked the dist. The positive karma already exists in the form of [GitHub Stargazers](https://github.com/masak/007/stargazers). If there is a way to do so, the implementation could simply be a proxy to give the user, while on modules.perl6.org, a way to "star" the dist.

Now, negative karma is more problematic. It can discourage the author of the dist and it doesn't provide any useful feedback on why the dist is receiving negative karma. A possible solution would be to convert all "downvotes" to reviews, where the user submitting the downvote has to explain why they're doing so. And thus, the Karma feature can be tied to `Dist Reviews` feature by subtracting from GitHub Stargazers the number of negative reviews.

## Dist Reviews
### Status of the implementation
No code yet.

### Description
This is pretty hard to get right. If implemented, it definitely needs an ability for authors and other users to **respond** to posted reviews. The idea is pretty simple: potential users of a dist can write about what their experience of using that dist was and give a rating (say from `0` to `10`) along with their review.

Perl 5 language has [a sample implementation](http://cpanratings.perl.org/) of the idea, but it has many problems and is far from ideal.

### Notable problems
#### Positive rating without a review
Some users may wish to give a "thumbs up" to a dist due to their positive experience, but they may not have a way with words or the time to write why they feel that way. To eliminate *"this is a great dist"* and similar overly-short reviews, we could set a minimum character limit and if the rating is positive, ask the user whether they wanted to simply increase the *Karma* (see above) of the dist.

#### Negative reviews aren't always deserved
Referring to the aforementioned Perl 5's implementation, a few years ago, one of the authors got dozens of dists rated with a single star and the text of all reviews contained one word *"lame."* Obviously, that reviewer had reasons other than code quality to engage in such drive-by down-rating, but any page that showed only the dist's star-rating, gave its viewers the impression that dist legitimately had bad rep. One way to address this is to weight the star-rating based on the ratio of how many users found the review helpful vs. those that didn't.

Another example is [genuine negative reviews based on the dist's quality](http://cpanratings.perl.org/dist/JSON-Create#12286) result hostilities between the authors on social media, Issue trackers, IRC, as well as [return negative reviews for no other reason than to retaliate](http://cpanratings.perl.org/dist/JSON-Meth#12308). This is why it's very important to allow for comments on reviews, as to provide the author a way to channel their potentially negative feelings, as well as clarify any misunderstandings about the module the reviewer might have.

## Authority Information
### Status of the implementation
No code yet, other than basic `author_id` stored in the `ModulesPerl6::Model::Dists` model.

### Description
In its basic state, the page could display all dists by a single author. A more useful featureset could include some info on the author as well as what dists they favourited (useful to keep track of what dists you used in the past that worked well). An implementation could be similar to [this page](https://metacpan.org/author/ZOFFIX), for example.

Along with providing some alternate ways for users to contact the author, the page could allow the author to log in and add an "about me" blurb or change the picture. This is to potentially make the author care more about their presence in the community and the quality of their code. The log in could be implemented via "log in with GitHub" so we don't have to roadblock users by requiring they register on the site.

### Notable Problems
Unlike [MetaCPAN](https://metacpan.org/), an "author" of a dist could well be an organization, like [perl6](https://github.com/perl6/). So it won't be a single person represented but an entity. This is not a bad thing and will actually make large projects worked on by many authors look nicer, instead of a single author getting all the credit by being the last one to make an update.

This is simply something the implementers of the feature have to keep in mind and accomodate.
