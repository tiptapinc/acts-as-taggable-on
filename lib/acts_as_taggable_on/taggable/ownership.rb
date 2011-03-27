module ActsAsTaggableOn::Taggable
  module Ownership
    def self.included(base)
      base.send :include, ActsAsTaggableOn::Taggable::Ownership::InstanceMethods
      base.extend ActsAsTaggableOn::Taggable::Ownership::ClassMethods

      base.class_eval do
        after_save :save_owned_tags
      end

      base.initialize_acts_as_taggable_on_ownership
    end

    module ClassMethods
      def acts_as_taggable_on(*args)
        initialize_acts_as_taggable_on_ownership
        super
      end

      def initialize_acts_as_taggable_on_ownership
        tag_types.each do |tag_type|
          class_eval %(
            def #{tag_type}_from(owner)
              owner_tag_list_on(owner, '#{tag_type}')
            end
          )
        end
      end
    end

    module InstanceMethods
      def owner_tags_on(owner, context)
        if owner
          base_tags.where(:taggings => {:context => context.to_s, :tagger_id => owner.id, :tagger_type => owner.class.to_s})
        else
          base_tags.where(:taggings => {:context => context.to_s})
        end
      end

      def cached_owned_tag_list_on(context)
        variable_name = "@owned_#{context}_list"
        cache = instance_variable_get(variable_name) || instance_variable_set(variable_name, {})
      end

      def owner_tag_list_on(owner, context)
        add_custom_context(context)

        cache = cached_owned_tag_list_on(context)
        cache.delete_if { |key, value| key.id == owner.id && key.class == owner.class }

        cache[owner] ||= ActsAsTaggableOn::Taggable::TagList.new(*owner_tags_on(owner, context).names)
      end

      def set_owner_tag_list_on(owner, context, new_list)
        add_custom_context(context)

        cache = cached_owned_tag_list_on(context)
        cache.delete_if { |key, value| key.id == owner.id && key.class == owner.class }

        cache[owner] = ActsAsTaggableOn::Taggable::TagList.from(new_list)
      end

      def reload(*args)
        self.class.tag_types.each do |context|
          instance_variable_set("@owned_#{context}_list", nil)
        end

        super
      end

      def save_owned_tags
        tagging_contexts.each do |context|
          cached_owned_tag_list_on(context).each do |owner, tag_list|
            # Find existing tags or create non-existing tags:
            tag_list = ActsAsTaggableOn::Tag.find_or_create_all_with_like_by_name(tag_list.uniq)

            owned_tags = owner_tags_on(owner, context)
            old_tags   = owned_tags - tag_list
            new_tags   = tag_list   - owned_tags

            # Find all taggings that belong to the taggable (self), are owned by the owner,
            # have the correct context, and are removed from the list.
            old_taggings = ActsAsTaggableOn::Tagging.where(:taggable_id => id, :taggable_type => self.class.base_class.to_s,
                                                           :tagger_type => owner.class.to_s, :tagger_id => owner.id,
                                                           :tag_id => old_tags, :context => context)

            if old_taggings.present?
              # Destroy old taggings:
              ActsAsTaggableOn::Tagging.destroy_all(:id => old_taggings.map {|tagging| tagging.id })
            end

            # Create new taggings:
            new_tags.each do |tag|
              taggings.create!(:tag_id => tag.id, :context => context.to_s, :tagger => owner, :taggable => self)
            end
          end
        end

        true
      end
    end
  end
end