# tree.rb - This file is part of the RubyTree package.
#
# $Revision$ by $Author$ on $Date$
#
# = tree.rb - Generic implementation of an N-ary tree data structure.
#
# Provides a generic tree data structure with ability to
# store keyed node elements in the tree.  This implementation
# mixes in the Enumerable module.
#
# Author:: Anupam Sengupta (anupamsg@gmail.com)
#

# Copyright (c) 2006, 2007, 2008, 2009, 2010 Anupam Sengupta
#
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
#
# - Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# - Redistributions in binary form must reproduce the above copyright notice, this
#   list of conditions and the following disclaimer in the documentation and/or
#   other materials provided with the distribution.
#
# - Neither the name of the organization nor the names of its contributors may
#   be used to endorse or promote products derived from this software without
#   specific prior written permission.
#
#   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

# This module provides a TreeNode class which is the primary class for representing
# nodes in the tree.
#
# This module mixes in the Enumerable module, and also acts as the namespace for all
# classes in RubyTree.
module Tree

  # Rubytree Package Version
  VERSION = '0.6.2'

  # == TreeNode Class Description
  #
  # This class models the nodes for an N-ary tree data structue. The nodes are +named+
  # and have a place-holder for the node data (i.e., `content' of the node). The node
  # names are required to be *unique* within the tree.
  #
  # The node content is not required to be unique across different nodes in the tree, and
  # can be +nil+ as well.
  #
  # The class provides various traversal methods to navigate the tree,
  # methods to modify contents of the node or to change position of the node in the tree
  # and methods to change structure of the tree.
  #
  # A node can have any number of child nodes attached to it and hence can be used to create N-ary trees.
  # Access to the child nodes can be made in order (with the conventional left to right access), or
  # randomly.
  #
  # The node also provides direct access to its parent and other superior parents in the path to
  # root of the tree.  In addition, a node can also access its sibling nodes, if present.
  # Note that while this implementation does not explicitly support directed graphs, the class itself makes
  # no restrictions on associating a node's +CONTENT+ with multiple nodes in the tree.
  #
  #
  # == Example
  #
  #  The following example implements this tree structure:
  #
  #                    +------------+
  #                    |    ROOT    |
  #                    +-----+------+
  #            +-------------+------------+
  #            |                          |
  #    +-------+-------+          +-------+-------+
  #    |  CHILD 1      |          |  CHILD 2      |
  #    +-------+-------+          +---------------+
  #            |
  #            |
  #    +-------+-------+
  #    | GRANDCHILD 1  |
  #    +---------------+
  #
  # require 'tree'
  #
  # root_node = Tree::TreeNode.new("ROOT", "Root Content")
  #
  # root_node << Tree::TreeNode.new("CHILD1", "Child1 Content") << Tree::TreeNode.new("GRANDCHILD1", "GrandChild1 Content")
  #
  # root_node << Tree::TreeNode.new("CHILD2", "Child2 Content")
  #
  # root_node.print_tree
  #
  # child1       = root_node["CHILD1"]
  #
  # grand_child1 = root_node["CHILD1"]["GRANDCHILD1"]
  #
  # siblings_of_child1 = child1.siblings # Will return an array
  #
  # children_of_root   = root_node.children # Will return an array
  #
  # # Process all nodes
  #
  # root_node.each { |node| node.content.reverse }
  #
  # root_node.remove!(child1) # Remove the child
  #
  class TreeNode
    include Enumerable

    # Name of this node.  Expected to be unique within the tree.
    attr_reader   :name

    # Content of this node.  Can be +nil+.
    attr_accessor :content

    # Parent of this node.  Will be +nil+ for root nodes.
    attr_reader   :parent


    # Constructor which expects the name of the node.
    # Name of the node is expected to be unique across the tree.
    #
    # The content can be of any type, defaults to +nil+.
    def initialize(name, content = nil)
      raise "Node name HAS to be provided" if name == nil
      @name = name
      @content = content
      self.set_as_root!

      @children_hash = Hash.new
      @children = []
    end

    # Returns a copy of the receiver node, with its parent and children links removed.
    # The original node remains attached to its tree.
    def detached_copy
      Tree::TreeNode.new(@name, @content ? @content.clone : nil)
    end

    # Print the string representation of this node.  This is primary for debugging purposes.
    def to_s
      "Node Name: #{@name}" +
        " Content: " + (@content || "<Empty>") +
        " Parent: " + (is_root?()  ? "<None>" : @parent.name) +
        " Children: #{@children.length}" +
        " Total Nodes: #{size()}"
    end

    # Returns an array of ancestors of the receiver node in reversed order
    # (the first element is the immediate parent of the receiver).
    #
    # Returns +nil+ if the receiver is a root node.
    def parentage
      return nil if is_root?

      parentage_array = []
      prev_parent = self.parent
      while (prev_parent)
        parentage_array << prev_parent
        prev_parent = prev_parent.parent
      end

      parentage_array
    end

    # Protected method to set the parent node for the receiver node.
    # This method should *NOT* be invoked by client code.
    #
    # Returns the parent.
    def parent=(parent)         # :nodoc:
      @parent = parent
    end

    # Convenience synonym for TreeNode#add method.
    #
    # This method allows an easy method to add node hierarchies to the tree
    # on a given path via chaining the method calls to successive child nodes.
    #
    # Example: <tt>root << child << grand_child</tt>
    #
    # Returns the added child node.
    def <<(child)
      add(child)
    end

    # Adds the specified child node to the receiver node.
    #
    # This method can also be used for *grafting* a subtree into the receiver node's tree, if the specified child node
    # is the root of a subtree (i.e., has child nodes under it).
    #
    # The receiver node becomes parent of the node passed in as the argument, and
    # the child is added as the last child ("right most") in the current set of
    # children of the receiver node.
    #
    # Returns the added child node.
    #
    # An exception is raised if another child node with the same name exists.
    def add(child)
      raise "Child already added" if @children_hash.has_key?(child.name)

      @children_hash[child.name]  = child
      @children << child
      child.parent = self
      return child
    end

    # Removes the specified child node from the receiver node.
    #
    # This method can also be used for *pruning* a subtree, in cases where the removed child node is
    # the root of the subtree to be pruned.
    #
    # The removed child node is orphaned but accessible if an alternate reference exists.  If accesible via
    # an alternate reference, the removed child will report itself as a root node for its subtree.
    #
    # Returns the child node.
    def remove!(child)
      @children_hash.delete(child.name)
      @children.delete(child)
      child.set_as_root! unless child == nil
      return child
    end

    # Removes the receiver node from its parent.  The reciever node becomes the new root for its subtree.
    #
    # If this is the root node, then does nothing.
    #
    # Returns self (the removed receiver node) if the operation is successful, and +nil+ otherwise.
    def remove_from_parent!
      @parent.remove!(self) unless is_root?
    end

    # Removes all children from the receiver node.
    #
    # Returns the receiver node.
    def remove_all!
      for child in @children
        child.set_as_root!
      end
      @children_hash.clear
      @children.clear
      self
    end

    # Returns +true+ if the receiver node has any associated content.
    def has_content?
      @content != nil
    end

    # Protected method which sets the receiver node as a root node.
    #
    # Returns +nil+.
    def set_as_root!              # :nodoc:
      @parent = nil
    end

    # Returns +true+ if the receiver is a root node.  Note that
    # orphaned children will also be reported as root nodes.
    def is_root?
      @parent == nil
    end

    # Returns +true+ if the receiver node has any immediate child nodes.
    def has_children?
      @children.length != 0
    end

    # Returns +true+ if the receiver node is a 'leaf' - i.e., one without
    # any children.
    def is_leaf?
      !has_children?
    end

    # Returns an array of all the immediate children of the receiver node.
    #
    # If a block is given, yields each child node to the block traversing from left to right.
    def children
      if block_given?
        @children.each {|child| yield child}
      else
        @children
      end
    end

    # Returns the first child of the receiver node.
    #
    # Will return +nil+ if no children are present.
    def first_child
      children.first
    end

    # Returns the last child of the receiver node.
    #
    # Will return +nil+ if no children are present.
    def last_child
      children.last
    end

    # Traverses every node (including the receiver node) from the (sub)tree
    # by yielding the node to the specified block.
    #
    # The traversal is depth-first and from left to right in pre-ordered sequence.
    def each &block             # :yields: node
      yield self
      children { |child| child.each(&block) }
    end

    # Traverses the tree in a pre-ordered sequence.  This is equivalent to
    # TreeNode#each
    def preordered_each &block  # :yields: node
      each(&block)
    end

    # Performs breadth first traversal of the tree starting at the receiver node. The
    # traversal at a given level is from left to right.
    def breadth_each &block
      node_queue = [self]       # Create a queue with self as the initial entry

      # Use a queue to do breadth traversal
      until node_queue.empty?
        node_to_traverse = node_queue.shift
        yield node_to_traverse
        # Enqueue the children from left to right.
        node_to_traverse.children { |child| node_queue.push child }
      end
    end

    # Yields all leaf nodes from the receiver node to the specified block.
    #
    # May yield this node as well if this is a leaf node.
    # Leaf traversal is depth-first and left to right.
    def each_leaf &block
      self.each { |node| yield(node) if node.is_leaf? }
    end

    # Returns the requested node from the set of immediate children.
    #
    # If the argument is _numeric_, then the in-sequence array of children is
    # accessed (see Tree#children).  If the argument is *NOT* _numeric_, then it
    # is assumed to be *name* of the child node to be returned.
    #
    # Raises an exception is the requested child node is not found.
    def [](name_or_index)
      raise "Name_or_index needs to be provided" if name_or_index == nil

      if name_or_index.kind_of?(Integer)
        @children[name_or_index]
      else
        @children_hash[name_or_index]
      end
    end

    # Returns the total number of nodes in this (sub)tree, including the receiver node.
    #
    # Size of the tree is defined as:
    #
    # Size:: Total number nodes in the subtree including the receiver node.
    def size
      @children.inject(1) {|sum, node| sum + node.size}
    end

    # Convenience synonym for Tree#size
    def length
      size()
    end

    # Pretty prints the tree starting with the receiver node.
    def print_tree(level = 0)

      if is_root?
        print "*"
      else
        print "|" unless parent.is_last_sibling?
        print(' ' * (level - 1) * 4)
        print(is_last_sibling? ? "+" : "|")
        print "---"
        print(has_children? ? "+" : ">")
      end

      puts " #{name}"

      children { |child| child.print_tree(level + 1)}
    end

    # Returns root node for the (sub)tree to which the receiver node belongs.
    #
    # Note that a root node's root is itself (*beware* of any loop construct that may become infinite!)
    #--
    # TODO: We should perhaps return nil as root's root.
    #++
    def root
      root = self
      root = root.parent while !root.is_root?
      root
    end

    # Returns the first sibling for the receiver node. If this is the root node, returns
    # itself.
    #
    # 'First' sibling is defined as follows:
    # First sibling:: The left-most child of the receiver's parent, which may be the receiver itself
    #--
    # TODO: Fix the inconsistency of returning root as its first sibling, and returning a
    #       a nil array for siblings for the node.
    #++
    def first_sibling
      is_root? ? self : parent.children.first
    end

    # Returns true if the receiver node is the first sibling.
    def is_first_sibling?
      first_sibling == self
    end

    # Returns the last sibling for the receiver node.  If this is the root node, returns
    # itself.
    #
    # 'Last' sibling is defined as follows:
    # Last sibling:: The right-most child of the receiver's parent, which may be the receiver itself
    #--
    # TODO: Fix the inconsistency of returning root as its last sibling, and returning a
    #       a nil array for siblings for the node.
    #++
    def last_sibling
      is_root? ? self : parent.children.last
    end

    # Returns true if the receivere node is the last sibling.
    def is_last_sibling?
      last_sibling == self
    end

    # Returns an array of siblings for the receiver node.  The receiver node is excluded.
    #
    # If a block is provided, yields each of the sibling nodes to the block.
    # The root always has +nil+ siblings.
    #--
    # TODO: Fix the inconsistency of returning root as its first/last sibling, and returning a
    #       a nil array for siblings for the node.
    #++
    def siblings
      return nil if is_root?

      if block_given?
        for sibling in parent.children
          yield sibling if sibling != self
        end
      else
        siblings = []
        parent.children {|my_sibling| siblings << my_sibling if my_sibling != self}
        siblings
      end
    end

    # Returns true if the receiver node is the only child of its parent.
    def is_only_child?
      parent.children.size == 1
    end

    # Returns the next sibling for the receiver node.
    # The 'next' node is defined as the node to right of the receiver node.
    #
    # Will return +nil+ if no subsequent node is present.
    def next_sibling
      if myidx = parent.children.index(self)
        parent.children.at(myidx + 1)
      end
    end

    # Returns the previous sibling for the receiver node.
    # The 'previous' node is defined as the node to left of the receiver node.
    #
    # Will return nil if no predecessor node is present.
    def previous_sibling
      if myidx = parent.children.index(self)
        parent.children.at(myidx - 1) if myidx > 0
      end
    end

    # Provides a comparision operation for the nodes.
    #
    # Comparision is based on the natural character-set ordering of the *node name*.
    def <=>(other)
      return +1 if other == nil
      self.name <=> other.name
    end

    # Freezes all nodes in the (sub)tree rooted at the receiver node.
    def freeze_tree!
      each {|node| node.freeze}
    end

    # Returns a marshal-dump represention of the (sub)tree rooted at the receiver node.
    def marshal_dump
      self.collect { |node| node.create_dump_rep }
    end

    # Creates a dump representation of the reciever node and returns the same as a hash.
    def create_dump_rep           # :nodoc:
      { :name => @name, :parent => (is_root? ? nil : @parent.name),  :content => Marshal.dump(@content)}
    end

    # Loads a marshalled dump of a tree and returns the root node of the
    # reconstructed tree. See the Marshal class for additional details.
    #
    #--
    # TODO: This method probably should be a class method.  It currently clobbers self
    #       and makes itself the root.
    #++
    def marshal_load(dumped_tree_array)
      nodes = { }
      for node_hash in dumped_tree_array do
        name        = node_hash[:name]
        parent_name = node_hash[:parent]
        content     = Marshal.load(node_hash[:content])

        if parent_name then
          nodes[name] = current_node = Tree::TreeNode.new(name, content)
          nodes[parent_name].add current_node
        else
          # This is the root node, hence initialize self.
          initialize(name, content)

          nodes[name] = self    # Add self to the list of nodes
        end
      end
    end

    # Creates a JSON representation of this node including all it children.
    def to_json(*a)
      begin
        require 'json'
        
        json_hash = {
          "name"         => name,
          "content"      => content,
          JSON.create_id => self.class.name
        }

        if has_children?
          json_hash["children"] = children
        end

        return json_hash.to_json
      rescue LoadError => e
        warn "The JSON-Gem couldn't be loaded. Due to this we cannot serialize the tree to a JSON representation"
      end
    end

    # Creates a Tree::TreeNode object instance from a given JSON Hash representation
    def self.json_create(json_hash)
      begin
        require 'json'

        node = new(json_hash["name"], json_hash["content"])
        json_hash["children"].each do |child|
          node << child
        end if json_hash["children"]
        
        return node
      rescue LoadError => e
        warn "The JSON-Gem couldn't be loaded. Due to this we cannot serialize the tree to a JSON representation"
      end
    end

    # Returns height of the (sub)tree from the receiver node.  Height of a node is defined as:
    #
    # Height:: Length of the longest downward path to a leaf from the node.
    #
    # - Height from a root node is height of the entire tree.
    # - The height of a leaf node is zero.
    def node_height
      return 0 if is_leaf?
      1 + @children.collect { |child| child.node_height }.max
    end

    # Returns depth of the receiver node in its tree.  Depth of a node is defined as:
    #
    # Depth:: Length of the node's path to its root.  Depth of a root node is zero.
    #
    # *Note* that the deprecated method Tree::TreeNode#depth was incorrectly computing this value.
    # Please replace all calls to the old method with Tree::TreeNode#node_depth instead.
    def node_depth
      return 0 if is_root?
      1 + parent.node_depth
    end

    # Returns depth of the tree from the receiver node. A single leaf node has a depth of 1.
    #
    # This method is *DEPRECATED* and may be removed in the subsequent releases.
    # Note that the value returned by this method is actually the:
    #
    # _height_ + 1 of the node, *NOT* the _depth_.
    #
    # For correct and conventional behavior, please use Tree::TreeNode#node_depth and
    # Tree::TreeNode#node_height methods instead.
    def depth
      begin
        require 'structured_warnings'   # To enable a nice way of deprecating of the depth method.
        warn DeprecatedMethodWarning, 'This method is deprecated.  Please use node_depth() or node_height() instead (bug # 22535)'
      rescue LoadError
        # Oh well. Will use the standard Kernel#warn.  Behavior will be identical.
        warn 'Tree::TreeNode#depth() method is deprecated.  Please use node_depth() or node_height() instead (bug # 22535)'
      end

      return 1 if is_leaf?
      1 + @children.collect { |child| child.depth }.max
    end
    
    def method_missing(meth, *args, &blk)
      if self.respond_to?(new_method_name = underscore(meth))
        begin
          require 'structured_warnings'   # To enable a nice way of deprecating of the depth method.
          warn DeprecatedMethodWarning, "The camelCased methods are deprecated. Please use #{new_method_name} instead of #{meth}"
        rescue LoadError
          # Oh well. Will use the standard Kernel#warn.  Behavior will be identical.
          warn "Tree::TreeNode##{meth}() method is deprecated. Please use #{new_method_name} instead."
        ensure
          send(new_method_name, *args, &blk)
        end
      else
        super
      end
    end

    # Returns breadth of the tree at the receiver node's  level.
    # A single node without siblings has a breadth of 1.
    #
    # Breadth is defined to be:
    # Breadth:: Number of sibling nodes to this node + 1 (this node itself), i.e., the number of children the parent of this node has.
    def breadth
      is_root? ? 1 : parent.children.size
    end

    protected :parent=, :set_as_root!, :create_dump_rep
    
    private

      # Just copied from ActiveSupport::Inflector because it is only needed
      # aliasing deprecated methods
      def underscore(camel_cased_word)
        word = camel_cased_word.to_s.dup
        word.gsub!(/::/, '/')
        word.gsub!(/([A-Z]+)([A-Z][a-z])/,'\1_\2')
        word.gsub!(/([a-z\d])([A-Z])/,'\1_\2')
        word.tr!("-", "_")
        word.downcase!
        word
      end

  end
end
