module Locomotive
  module Import
    module ContentTypes

      def self.process(context)
        site, database = context[:site], context[:database]

        content_types = database['site']['content_types']

        return if content_types.nil?

        content_types.each do |name, attributes|
          puts "\t\t....content_type = #{attributes['slug']}"

          content_type = site.content_types.where(:slug => attributes['slug']).first

          content_type ||= self.build_content_type(site, attributes.merge(:name => name))

          self.add_or_update_fields(content_type, attributes['fields'])

          self.set_highlighted_field_name(content_type)

          self.set_order_by_value(content_type)

          self.set_group_by_value(content_type)

          content_type.save!

          site.reload
        end
      end

      def self.build_content_type(site, data)
        attributes = { :order_by => '_position_in_list', :group_by_field_name => data.delete('group_by') }.merge(data)

        attributes.delete_if { |name, value| %w{fields contents}.include?(name) }

        site.content_types.build(attributes)
      end

      def self.add_or_update_fields(content_type, fields)
        fields.each_with_index do |data, position|
          name, data = data.keys.first, data.values.first

          attributes = { :_alias => name, :label => name.humanize, :kind => 'string', :position => position }.merge(data).symbolize_keys

          field = content_type.content_custom_fields.detect { |f| f._alias == attributes[:_alias] }

          field ||= content_type.content_custom_fields.build(attributes)

          field.send(:set_unique_name!) if field.new_record?

          field.attributes = attributes
        end
      end

      def self.set_highlighted_field_name(content_type)
        field = content_type.content_custom_fields.detect { |f| f._alias == content_type.highlighted_field_name }

        content_type.highlighted_field_name = field._name if field
      end

      def self.set_order_by_value(content_type)
        order_by = (case content_type.order_by
        when 'manually', '_position_in_list' then '_position_in_list'
        when 'date', 'updated_at' then 'updated_at'
        else
          content_type.content_custom_fields.detect { |f| f._alias == content_type.order_by }._name rescue nil
        end)

        content_type.order_by = order_by || '_position_in_list'
      end

      def self.set_group_by_value(content_type)
        return if content_type.group_by_field_name.blank?

        field = content_type.content_custom_fields.detect { |f| f._alias == content_type.group_by_field_name }

        content_type.group_by_field_name = field._name if field
      end

    end
  end
end