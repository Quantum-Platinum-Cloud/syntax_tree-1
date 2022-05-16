# frozen_string_literal: true

module SyntaxTree
  # A slightly enhanced PP that knows how to format recursively including
  # comments.
  class Formatter < PrettierPrint
    COMMENT_PRIORITY = 1
    HEREDOC_PRIORITY = 2

    attr_reader :source, :stack

    # These options are overridden in plugins to we need to make sure they are
    # available here.
    attr_reader :quote, :trailing_comma
    alias trailing_comma? trailing_comma

    def initialize(source, ...)
      super(...)

      @source = source
      @stack = []
      @quote = "\""
      @trailing_comma = false
    end

    def self.format(source, node)
      formatter = new(source, [])
      node.format(formatter)
      formatter.flush
      formatter.output.join
    end

    def format(node, stackable: true)
      stack << node if stackable
      doc = nil

      # If there are comments, then we're going to format them around the node
      # so that they get printed properly.
      if node.comments.any?
        leading, trailing = node.comments.partition(&:leading?)

        # Print all comments that were found before the node.
        leading.each do |comment|
          comment.format(self)
          breakable(force: true)
        end

        # If the node has a stree-ignore comment right before it, then we're
        # going to just print out the node as it was seen in the source.
        doc =
          if leading.last&.ignore?
            text(source[node.location.start_char...node.location.end_char])
          else
            node.format(self)
          end

        # Print all comments that were found after the node.
        trailing.each do |comment|
          line_suffix(priority: COMMENT_PRIORITY) do
            comment.inline? ? text(" ") : breakable
            comment.format(self)
            break_parent
          end
        end
      else
        doc = node.format(self)
      end

      stack.pop if stackable
      doc
    end

    def format_each(nodes)
      nodes.each { |node| format(node) }
    end

    def parent
      stack[-2]
    end

    def parents
      stack[0...-1].reverse_each
    end
  end
end
