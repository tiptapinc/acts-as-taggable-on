module ActsAsTaggableOn
  module Tag
    def acts_as_tag(opts = {})
      opts.assert_valid_keys :tagging
      tagging_class_name = opts[:tagging] || 'Tagging'

      class_eval do
        attr_accessible :name

        ### ASSOCIATIONS:

        has_many :taggings, :dependent => :destroy, :class_name => tagging_class_name

        ### VALIDATIONS:
        validates_presence_of :name
        validates_uniqueness_of :name

        ### SCOPES:
        scope :named, lambda {|name| where(["name #{ActsAsTaggableOn.like_operator} ?", name]) }
        scope :named_any, lambda {|list| where(list.map { |tag| sanitize_sql(["name #{ActsAsTaggableOn.like_operator} ?", tag.to_s]) }.join(" OR ")) }
        scope :named_like, lambda {|name| where(["name #{ActsAsTaggableOn.like_operator} ?", "%#{name}%"]) }
        scope :named_like_any, lambda {|list| where(list.map { |tag| sanitize_sql(["name #{ActsAsTaggableOn.like_operator} ?", "%#{tag.to_s}%"]) }.join(" OR ")) }
      end

      include ActsAsTaggableOn::Tag::InstanceMethods
      extend ActsAsTaggableOn::Tag::ClassMethods
    end

    module ClassMethods
      def find_or_create_with_like_by_name(name)
        named_like(name).first || create(:name => name)
      end

      def find_or_create_all_with_like_by_name(*list)
        list = list.flatten
        return [] if list.empty?

        existing_tags = named_any(list)
        new_tag_names = list.reject do |name|
                          name = comparable_name(name)
                          existing_tags.any? { |tag| comparable_name(tag.name) == name }
                        end
        created_tags  = new_tag_names.map { |name| create(:name => name) }

        existing_tags + created_tags
      end

      def names
        all.map {|tag| tag.name }
      end

    private
      def comparable_name(str)
        RUBY_VERSION >= "1.9" ? str.downcase : str.mb_chars.downcase
      end
    end

    module InstanceMethods
      def ==(object)
        super || (object.is_a?(self.class) && name == object.name)
      end

      def to_s
        name
      end

      def count
        read_attribute(:count).to_i
      end
    end
  end
end
