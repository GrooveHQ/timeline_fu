module TimelineFu
  module Fires
    def self.included(klass)
      klass.send(:extend, ClassMethods)
    end

    module ClassMethods
      def fires(event_type, opts)
        raise ArgumentError, "Argument :on is mandatory" unless opts.has_key?(:on)

        # Array provided, set multiple callbacks
        if opts[:on].kind_of?(Array)
          opts[:on].each { |on| fires(event_type, opts.merge({:on => on})) }
          return
        end

        opts[:subject] = :self unless opts.has_key?(:subject)

        method_name = :"fire_#{event_type}_after_#{opts[:on]}"
        define_method(method_name) do
          create_options = [:actor, :subject, :secondary_subject].inject({}) do |memo, sym|
            if opts[sym]
              if opts[sym].respond_to?(:call)
                memo[sym] = opts[sym].call(self)
              elsif opts[sym] == :self
                memo[sym] = self
              else
                memo[sym] = send(opts[sym])
              end
            end
            memo
          end
          create_options[:event_type] = event_type.to_s
          create_options[:changed_fields] = self.changes
          create_options[:subject_string] = self.generate_timeline_event_summary if self.respond_to?(:generate_activity_log_summary)
          try_title = self.try(:title) rescue nil
          try_title ||= self.try(:name) rescue nil
          create_options[:subject_string] ||= "#{self.class.name.underscore.humanize} ##{self.id}#{" \"#{try_title}\"" unless try_title.blank?}"

          TimelineEvent.create!(create_options)
        end

        send(:"after_#{opts[:on]}", method_name, :if => opts[:if])
      end
    end
  end
end
