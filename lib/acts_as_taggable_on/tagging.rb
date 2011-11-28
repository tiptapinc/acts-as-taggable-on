module ActsAsTaggableOn
  module Tagging
    def acts_as_tagging(opts = {})
      opts.assert_valid_keys :tag
      tag_class_name = opts[:tag] || 'Tag'

      class_eval do
        attr_accessible :tag,
                        :tag_id,
                        :context,
                        :taggable,
                        :taggable_type,
                        :taggable_id,
                        :tagger,
                        :tagger_type,
                        :tagger_id

        belongs_to :tag, :class_name => tag_class_name, :counter_cache => true
        belongs_to :taggable, :polymorphic => true
        belongs_to :tagger,   :polymorphic => true

        validates_presence_of :context
        validates_presence_of :tag_id

        validates_uniqueness_of :tag_id, :scope => [ :taggable_type, :taggable_id, :context, :tagger_id, :tagger_type ]
      end
    end
  end
end
