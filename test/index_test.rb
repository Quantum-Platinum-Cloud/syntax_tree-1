# frozen_string_literal: true

require_relative "test_helper"

module SyntaxTree
  class IndexTest < Minitest::Test
    def test_module
      index_each("module Foo; end") do |entry|
        assert_equal :Foo, entry.name
        assert_empty entry.nesting
      end
    end

    def test_module_nested
      index_each("module Foo; module Bar; end; end") do |entry|
        assert_equal :Bar, entry.name
        assert_equal [:Foo], entry.nesting
      end
    end

    def test_module_comments
      index_each("# comment1\n# comment2\nmodule Foo; end") do |entry|
        assert_equal :Foo, entry.name
        assert_equal ["# comment1", "# comment2"], entry.comments.to_a
      end
    end

    def test_class
      index_each("class Foo; end") do |entry|
        assert_equal :Foo, entry.name
        assert_empty entry.nesting
      end
    end

    def test_class_nested
      index_each("class Foo; class Bar; end; end") do |entry|
        assert_equal :Bar, entry.name
        assert_equal [:Foo], entry.nesting
      end
    end

    def test_class_comments
      index_each("# comment1\n# comment2\nclass Foo; end") do |entry|
        assert_equal :Foo, entry.name
        assert_equal ["# comment1", "# comment2"], entry.comments.to_a
      end
    end

    def test_method
      index_each("def foo; end") do |entry|
        assert_equal :foo, entry.name
        assert_empty entry.nesting
      end
    end

    def test_method_nested
      index_each("class Foo; def foo; end; end") do |entry|
        assert_equal :foo, entry.name
        assert_equal [:Foo], entry.nesting
      end
    end

    def test_method_comments
      index_each("# comment1\n# comment2\ndef foo; end") do |entry|
        assert_equal :foo, entry.name
        assert_equal ["# comment1", "# comment2"], entry.comments.to_a
      end
    end

    def test_singleton_method
      index_each("def self.foo; end") do |entry|
        assert_equal :foo, entry.name
        assert_empty entry.nesting
      end
    end

    def test_singleton_method_nested
      index_each("class Foo; def self.foo; end; end") do |entry|
        assert_equal :foo, entry.name
        assert_equal [:Foo], entry.nesting
      end
    end

    def test_singleton_method_comments
      index_each("# comment1\n# comment2\ndef self.foo; end") do |entry|
        assert_equal :foo, entry.name
        assert_equal ["# comment1", "# comment2"], entry.comments.to_a
      end
    end

    def test_this_file
      entries = Index.index_file(__FILE__, backend: Index::ParserBackend.new)

      if defined?(RubyVM::InstructionSequence)
        entries += Index.index_file(__FILE__, backend: Index::ISeqBackend.new)
      end

      entries.map { |entry| entry.comments.to_a }
    end

    private

    def index_each(source)
      yield Index.index(source, backend: Index::ParserBackend.new).last

      if defined?(RubyVM::InstructionSequence)
        yield Index.index(source, backend: Index::ISeqBackend.new).last
      end
    end
  end
end
