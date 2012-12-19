class Role
  class TypeList
    
    attr_reader :layer
    
    def initialize(layer_type)
      @layer = layer_type
      compose
    end
        
    def each(&block)
      @role_types.each(&block)
    end
    
    private
    
    # hash with the form {layer: {group: [roles]}}
    def compose
      @global_group_types = find_global_group_types([], layer).uniq
      @global_role_types = find_global_role_types(layer).uniq
      @role_types = Hash.new { |h, k| h[k] = Hash.new { |h, k| h[k] = [] } }
      
      # layers
      compose_role_list_by_layer(layer)
      # global groups
      @global_group_types.each do |group|
        types = local_role_types(group)
        @role_types['Global'][group.model_name.human] = types if types.present?
      end
      # global roles
      @role_types['Global']['Global'] = @global_role_types if @global_role_types.present?
    end

    def compose_role_list_by_layer(layer)
      set_role_types(layer, layer)
      layer.possible_children.each do |child|
        if child.layer
          compose_role_list_by_layer(child)
        elsif !@global_group_types.include?(child)
          set_role_types(layer, child)
        end
      end
    end
    
    def set_role_types(layer, group)
      types = local_role_types(group)
      @role_types[layer.model_name.human][group.model_name.human] = types if types.present?
    end
    
    # groups appearing in the possible children of more than one group
    def find_global_group_types(seen_types, group)
      global = []
      group.possible_children.each do |child|
        if seen_types.include?(child)
          global << child unless child.layer
        else
          seen_types << child
          global.concat(find_global_group_types(seen_types, child))
        end
      end
      global
    end
    
    # role types appearing in more than one group
    def find_global_role_types(group)
      global = []
      seen_types = []
      group.child_types.each do |child|
        child.roles.each do |role|
          if seen_types.include?(role)
            global << role
          end
          seen_types << role
        end
      end
      global
    end
        
    def local_role_types(group)
      group.role_types.select {|r| !r.restricted && local_role_type?(r) }
    end
    
    def local_role_type?(type)
      !@global_role_types.include?(type)
    end
  
  end
end