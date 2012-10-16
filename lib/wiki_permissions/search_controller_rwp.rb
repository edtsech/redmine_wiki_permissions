module WikiPermissions
  module SearchControllerRwp
    def self.included(base)
      base.send(:include, InstanceMethods)
      base.class_eval do
	unloadable
        alias_method :_index, :index unless method_defined? :_index
      end
    end
    module InstanceMethods
      def index
	_index
	
	if @results != nil
	  @results.delete_if do |result|
	    result.class == WikiPage and
	    not User.current.can_view? result
	  end
	end
      end
    end
  end
end
