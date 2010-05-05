#!/usr/bin/env ruby

# test_binarytree.rb - This file is part of the RubyTree package.
#
# $Revision$ by $Author$ on $Date$
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

require 'test/unit'
require 'tree/binarytree'

module TestTree
  # Test class for the binary tree node.
  class TestBinaryTreeNode < Test::Unit::TestCase

    def setup
      @root = Tree::BinaryTreeNode.new("ROOT", "Root Node")

      @left_child1  = Tree::BinaryTreeNode.new("A Child at Left", "Child Node @ left")
      @right_child1 = Tree::BinaryTreeNode.new("B Child at Right", "Child Node @ right")
    end

    def teardown
      @root.remove!(@left_child1)
      @root.remove!(@right_child1)
      @root = nil
    end

    def test_initialize
      assert_not_nil(@root, "Binary tree's Root should have been created")
    end

    def test_add
      @root.add  @left_child1
      assert_same(@left_child1, @root.left_child, "The left node should be left_child1")
      assert_same(@left_child1, @root.first_child, "The first node should be left_child1")

      @root.add @right_child1
      assert_same(@right_child1, @root.right_child, "The right node should be right_child1")
      assert_same(@right_child1, @root.last_child, "The first node should be right_child1")

      assert_raise RuntimeError do
        @root.add Tree::BinaryTreeNode.new("The third child!")
      end

      assert_raise RuntimeError do
        @root << Tree::BinaryTreeNode.new("The third child!")
      end
    end

    def test_left_child
      @root << @left_child1
      @root << @right_child1
      assert_same(@left_child1, @root.left_child, "The left child should be 'left_child1")
      assert_not_same(@right_child1, @root.left_child, "The right_child1 is not the left child")
    end

    def test_right_child
      @root << @left_child1
      @root << @right_child1
      assert_same(@right_child1, @root.right_child, "The right child should be 'right_child1")
      assert_not_same(@left_child1, @root.right_child, "The left_child1 is not the left child")
    end

    def test_left_child_equals
      @root << @left_child1
      @root << @right_child1
      assert_same(@left_child1, @root.left_child, "The left child should be 'left_child1")

      @root.left_child = Tree::BinaryTreeNode.new("New Left Child")
      assert_equal("New Left Child", @root.left_child.name, "The left child should now be the new child")
      assert_equal("B Child at Right", @root.last_child.name, "The last child should now be the right child")

      # Now set the left child as nil, and retest
      @root.left_child = nil
      assert_nil(@root.left_child, "The left child should now be nil")
      assert_nil(@root.first_child, "The first child is now nil")
      assert_equal("B Child at Right", @root.last_child.name, "The last child should now be the right child")
    end

    def test_right_child_equals
      @root << @left_child1
      @root << @right_child1
      assert_same(@right_child1, @root.right_child, "The right child should be 'right_child1")

      @root.right_child = Tree::BinaryTreeNode.new("New Right Child")
      assert_equal("New Right Child", @root.right_child.name, "The right child should now be the new child")
      assert_equal("A Child at Left", @root.first_child.name, "The first child should now be the left child")
      assert_equal("New Right Child", @root.last_child.name, "The last child should now be the right child")

      # Now set the right child as nil, and retest
      @root.right_child = nil
      assert_nil(@root.right_child, "The right child should now be nil")
      assert_equal("A Child at Left", @root.first_child.name, "The first child should now be the left child")
      assert_nil(@root.last_child, "The first child is now nil")
    end

    def test_is_left_child_eh
      @root << @left_child1
      @root << @right_child1

      assert(@left_child1.is_left_child?, "left_child1 should be the left child")
      assert(!@right_child1.is_left_child?, "left_child1 should be the left child")

      # Now set the right child as nil, and retest
      @root.right_child = nil
      assert(@left_child1.is_left_child?, "left_child1 should be the left child")

      assert(!@root.is_left_child?, "Root is neither left child nor right")
    end

    def test_is_right_child_eh
      @root << @left_child1
      @root << @right_child1

      assert(@right_child1.is_right_child?, "right_child1 should be the right child")
      assert(!@left_child1.is_right_child?, "right_child1 should be the right child")

      # Now set the left child as nil, and retest
      @root.left_child = nil
      assert(@right_child1.is_right_child?, "right_child1 should be the right child")
      assert(!@root.is_right_child?, "Root is neither left child nor right")
    end

    def test_swap_children
      @root << @left_child1
      @root << @right_child1

      assert(@right_child1.is_right_child?, "right_child1 should be the right child")
      assert(!@left_child1.is_right_child?, "right_child1 should be the right child")

      @root.swap_children

      assert(@right_child1.is_left_child?, "right_child1 should now be the left child")
      assert(@left_child1.is_right_child?, "left_child1 should now be the right child")
      assert_equal(@right_child1, @root.first_child, "right_child1 should now be the first child")
      assert_equal(@left_child1, @root.last_child, "left_child1 should now be the last child")
      assert_equal(@right_child1, @root[0], "right_child1 should now be the first child")
      assert_equal(@left_child1, @root[1], "left_child1 should now be the last child")
    end
    
    def test_old_camelCase_method_names
      @left_child2  = Tree::BinaryTreeNode.new("A Child at Left", "Child Node @ left")
      @right_child2 = Tree::BinaryTreeNode.new("B Child at Right", "Child Node @ right")
      
      @root.leftChild
      @root.leftChild = @left_child2
      @root.isLeftChild?
      @root.rightChild
      @root.rightChild = @right_child2
      @root.isRightChild?
      @root.swapChildren
    end
    
  end
end
