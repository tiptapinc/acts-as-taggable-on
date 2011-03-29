module ActsAsTaggableOn::Taggable
  module Related
    def self.included(base)
      base.send :include, ActsAsTaggableOn::Taggable::Related::InstanceMethods
      base.extend ActsAsTaggableOn::Taggable::Related::ClassMethods
      base.initialize_acts_as_taggable_on_related
    end

    module ClassMethods
      def initialize_acts_as_taggable_on_related
        tag_types.each do |tag_type|
          class_eval %(
            def find_related_#{tag_type}
              related_tags_for('#{tag_type}', self.class)
            end
            alias_method :find_related_on_#{tag_type}, :find_related_#{tag_type}

            def find_related_#{tag_type}_for(klass)
              related_tags_for('#{tag_type}', klass)
            end

            def find_matching_contexts(search_context, result_context)
              matching_contexts_for(search_context.to_s, result_context.to_s, self.class)
            end

            def find_matching_contexts_for(klass, search_context, result_context)
              matching_contexts_for(search_context.to_s, result_context.to_s, klass)
            end
          )
        end
      end

      def acts_as_taggable_on(*args)
        super
        initialize_acts_as_taggable_on_related
      end
    end

    module InstanceMethods
      def matching_contexts_for(search_context, result_context, klass)
        related_tags_for(search_context, klass).where("#{acts_as_taggable_on_tagging_model.table_name}.context = ?", result_context)
      end

      def related_tags_for(context, klass)
        tags_to_find = tags_on(context).collect { |t| t.name }

        scope = klass.scoped
        scope = scope.where("#{klass.table_name}.id != ?", id) if self.class == klass # exclude self
        scope.select("#{klass.table_name}.*, COUNT(#{acts_as_taggable_on_tag_model.table_name}.id) AS count").
          from("#{klass.table_name}, #{acts_as_taggable_on_tag_model.table_name}, #{acts_as_taggable_on_tagging_model.table_name}").
          where("#{klass.table_name}.id = #{acts_as_taggable_on_tagging_model.table_name}.taggable_id").
          where("#{acts_as_taggable_on_tagging_model.table_name}.taggable_type = ?", klass.to_s).
          where("#{acts_as_taggable_on_tagging_model.table_name}.tag_id = #{acts_as_taggable_on_tag_model.table_name}.id").
          where("#{acts_as_taggable_on_tag_model.table_name}.name IN (?)", tags_to_find).
          group(grouped_column_names_for(klass)).
          order("count DESC")
      end
    end
  end
end