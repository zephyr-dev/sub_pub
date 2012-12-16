module SubPub
  module ActiveRecordExtensions
    extend ActiveSupport::Concern

    included do
      ['before_create', 'after_create', 'after_commit'].each do |callback|
        class_eval "
          #{callback} do
            notify_pub_sub_of_active_record_callback('#{callback}')
          end
        "
      end
    end

    private

    def notify_pub_sub_of_active_record_callback(callback)
      message = "active_record::#{self.class.to_s.underscore}::#{callback}"
      SubPub.publish(message, record: self)
    end
  end

  class Railtie < Rails::Railtie
    initializer "pub sub configuration of active record extensions" do
      class ::ActiveRecord::Base
        include SubPub::ActiveRecordExtensions
      end

      config.after_initialize do
        Dir[
          File.expand_path("app/models/pub_sub/*.rb", Rails.root)
        ].each { |file| require file }
      end
    end
  end

  module ActiveRecord
    class Subscriber < SubPub::Subscriber
      def self.subscribe_to(class_instance, callback)
        super("active_record::#{class_instance.to_s.underscore}::#{callback}")
      end

      def record
        options[:record]
      end
    end
  end
end
