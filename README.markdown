ActsAsTaggableOn
================

In your Rails 3 tagging your models since 2011.

What's it good for?
-------------------

For instance, in a social network, a user might have tags that are called skills,
interests, sports, and more. There is no real way to differentiate between tags and
so an implementation of this type is not possible with acts as taggable on steroids.

Enter Acts as Taggable On. Rather than tying functionality to a specific keyword
(namely "tags"), acts as taggable on allows you to specify an arbitrary number of
tag "contexts" that can be used locally or in combination in the same way steroids
was used.


Installation
============

Rails 3.0
---------

Acts As Taggable On is now useable in Rails 3.0, thanks to the excellent work of Szymon Nowak
and Jelle Vandebeeck.

To use it, add it to your Gemfile:

    gem 'acts-as-taggable-on'

Post Installation
-----------------

1. `rails generate acts_as_taggable_on:migration`
2. `rake db:migrate`


Testing
=======

Acts As Taggable On uses RSpec for its test coverage. Inside the plugin
directory, you can run the specs for RoR 3.0.0 with:

    rake spec

If you already have RSpec on your application, the specs will run while using:

    rake spec:plugins


Usage
=====

    class User < ActiveRecord::Base
      # Alias for acts_as_taggable_on :tags:
      acts_as_taggable
      acts_as_taggable_on :skills, :interests
    end

    @user = User.new(:name => "Bobby")
    @user.tag_list = "awesome, slick, hefty"      # this should be familiar
    @user.skill_list = "joking, clowning, boxing" # but you can do it for any context!
    @user.skill_list                              # => ["joking","clowning","boxing"] as TagList
    @user.save

    @user.tags # => [<Tag name:"awesome">,<Tag name:"slick">,<Tag name:"hefty">]
    @user.skills # => [<Tag name:"joking">,<Tag name:"clowning">,<Tag name:"boxing">]

    @frankie = User.create(:name => "Frankie", :skill_list => "joking, flying, eating")
    User.skill_counts # => [<Tag name="joking" count=2>,<Tag name="clowning" count=1>...]
    @frankie.skill_counts


Finding Tagged Objects
----------------------

Acts As Taggable On utilizes `named_scope` to create an association for tags.
This way you can mix and match to filter down your results, and it also improves
compatibility with the `will_paginate` gem:

    class User < ActiveRecord::Base
      acts_as_taggable_on :tags
      named_scope :by_join_date, :order => "created_at DESC"
    end

    User.tagged_with("awesome").by_date
    User.tagged_with("awesome").by_date.paginate(:page => params[:page], :per_page => 20)

    # Find a user with matching all tags, not just one
    User.tagged_with(["awesome", "cool"], :match_all => :true)

    # Find a user with any of the tags:
    User.tagged_with(["awesome", "cool"], :any => true)


Relationships
-------------

You can find objects of the same type based on similar tags on certain contexts.
Also, objects will be returned in descending order based on the total number of
matched tags.

    @bobby = User.find_by_name("Bobby")
    @bobby.skill_list # => ["jogging", "diving"]

    @frankie = User.find_by_name("Frankie")
    @frankie.skill_list # => ["hacking"]

    @tom = User.find_by_name("Tom")
    @tom.skill_list # => ["hacking", "jogging", "diving"]

    @tom.find_related_skills # => [<User name="Bobby">,<User name="Frankie">]
    @bobby.find_related_skills # => [<User name="Tom">]
    @frankie.find_related_skills # => [<User name="Tom">]


Dynamic Tag Contexts
--------------------

In addition to the generated tag contexts in the definition, it is also possible
to allow for dynamic tag contexts (this could be user generated tag contexts!)

    @user = User.new(:name => "Bobby")
    @user.set_tag_list_on(:customs, "same, as, tag, list")
    @user.tag_list_on(:customs) # => ["same","as","tag","list"]
    @user.save
    @user.tags_on(:customs) # => [<Tag name='same'>,...]
    @user.tag_counts_on(:customs)
    User.tagged_with("same", :on => :customs) # => [@user]


Tag Ownership
-------------

Tags can have owners:

    class User < ActiveRecord::Base
      acts_as_tagger
    end

    class Photo < ActiveRecord::Base
      acts_as_taggable_on :locations
    end

    @some_user.tag(@some_photo, :with => "paris, normandy", :on => :locations)
    @some_user.owned_taggings
    @some_user.owned_tags
    @some_photo.locations_from(@some_user)


Tag cloud calculations
----------------------

To construct tag clouds, the frequency of each tag needs to be calculated.
Because we specified `acts_as_taggable_on` on the `User` class, we can
get a calculation of all the tag counts by using `User.tag_counts_on(:customs)`. But what if we wanted a tag count for
an single user's posts? To achieve this we call `tag_counts` on the association:

    User.find(:first).posts.tag_counts_on(:tags)

A helper is included to assist with generating tag clouds.

Here is an example that generates a tag cloud.

Helper:

    module PostsHelper
      include ActsAsTaggableOn::TagsHelper
    end

Controller:

    class PostController < ApplicationController
      def tag_cloud
        @tags = Post.tag_counts_on(:tags)
      end
    end

View:

    <% tag_cloud(@tags, %w(css1 css2 css3 css4)) do |tag, css_class| %>
      <%= link_to tag.name, { :action => :tag, :id => tag.name }, :class => css_class %>
    <% end %>

CSS:

    .css1 { font-size: 1.0em; }
    .css2 { font-size: 1.2em; }
    .css3 { font-size: 1.4em; }
    .css4 { font-size: 1.6em; }


Contributors
============

This plugin was originally based on **Acts as Taggable on Steroids** by Jonathan Viney.
It has evolved substantially since that point, but all credit goes to him for the
initial tagging functionality that so many people have used.

- Anthony Cook (acook) - Fork Maintainer
- TomEric (i76) - A Former Maintainer
- Michael Bleigh - Original Author
- Szymon Nowak - Rails 3.0 compatibility
- Jelle Vandebeeck - Rails 3.0 compatibility
- Brendan Lim - Related Objects
- Pradeep Elankumaran - Taggers
- Sinclair Bain - Patch King
- tristanzdunn - Related objects of other classes
- azabaj - Fixed migrate down
- Peter Cooper - named_scope fix
- slainer68 - STI fix
- harrylove - migration instructions and fix-ups
- lawrencepit - cached tag work
- sobrinho - fixed tag_cloud helper
- Empact - compatibility, refactoring, rails extraction, more
- kuldarkrabbi - inheritable attributes deprecation fix
- revelation - STI fix
- brady8 - force lowercase and parameterize tags


Original Copyright
------------------

Copyright (c) 2007-2010 Michael Bleigh (http://mbleigh.com/) and Intridea Inc. (http://intridea.com/), released under the MIT license
