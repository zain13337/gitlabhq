# frozen_string_literal: true

module Banzai
  module Filter
    # HTML Filter for parsing Gollum's tags in HTML. It's only parses the
    # following tags:
    #
    # - Link to internal pages:
    #
    #   * [[Bug Reports]]
    #   * [[How to Contribute|Contributing]]
    #
    # - Link to external resources:
    #
    #   * [[http://en.wikipedia.org/wiki/Git_(software)]]
    #   * [[Git|http://en.wikipedia.org/wiki/Git_(software)]]
    #
    # - Link internal images, the special attributes will be ignored:
    #
    #   * [[images/logo.png]]
    #   * [[images/logo.png|alt=Logo]]
    #
    # - Link external images, the special attributes will be ignored:
    #
    #   * [[http://example.com/images/logo.png]]
    #   * [[http://example.com/images/logo.png|alt=Logo]]
    #
    # Based on Gollum::Filter::Tags
    #
    # Note: the table of contents tag is now handled by TableOfContentsTagFilter
    #
    # Context options:
    #   :wiki [Wiki] (required) - Current wiki instance.
    #
    class GollumTagsFilter < HTML::Pipeline::Filter
      include ActionView::Helpers::TagHelper

      # Pattern to match tags content that should be parsed in HTML.
      #
      # Gollum's tags have been made to resemble the tags of other markups,
      # especially MediaWiki. The basic syntax is:
      #
      # [[tag]]
      #
      # Some tags will accept attributes which are separated by pipe
      # symbols.Some attributes must precede the tag and some must follow it:
      #
      # [[prefix-attribute|tag]]
      # [[tag|suffix-attribute]]
      #
      # See https://github.com/gollum/gollum/wiki
      #
      # Rubular: http://rubular.com/r/7dQnE5CUCH
      TAGS_PATTERN_UNTRUSTED = '\[\[(.+?)\]\]'
      TAGS_PATTERN_UNTRUSTED_REGEX =
        Gitlab::UntrustedRegexp.new(TAGS_PATTERN_UNTRUSTED, multiline: false).freeze

      # Pattern to match allowed image extensions
      ALLOWED_IMAGE_EXTENSIONS = /.+(jpg|png|gif|svg|bmp)\z/i

      # Do not perform linking inside these tags.
      IGNORED_ANCESTOR_TAGS = %w[pre code tt].to_set

      def call
        doc.xpath('descendant-or-self::text()').each do |node|
          next if has_ancestor?(node, IGNORED_ANCESTOR_TAGS)
          next unless TAGS_PATTERN_UNTRUSTED_REGEX.match?(node.content)

          html = TAGS_PATTERN_UNTRUSTED_REGEX.replace_gsub(CGI.escapeHTML(node.content)) do |match|
            process_tag(CGI.unescapeHTML(match[1]))&.to_s || match[0]
          end

          node.replace(html)
        end

        doc
      end

      private

      # Process a single tag into its final HTML form.
      #
      # tag - The String tag contents (the stuff inside the double brackets).
      #
      # Returns the String HTML version of the tag.
      def process_tag(tag)
        parts = tag.split('|')

        return if parts.empty?

        process_image_tag(parts) || process_page_link_tag(parts)
      end

      # Attempt to process the tag as an image tag.
      #
      # tag - The String tag contents (the stuff inside the double brackets).
      #
      # Returns the String HTML if the tag is a valid image tag or nil
      # if it is not.
      def process_image_tag(parts)
        content = parts[0].strip

        return unless image?(content)

        path =
          if url?(content)
            content
          elsif wiki && file = wiki.find_file(content, load_content: false)
            file.path
          end

        if path
          sanitized_content_tag(:img, nil, src: path, class: 'gfm')
        end
      end

      def image?(path)
        path =~ ALLOWED_IMAGE_EXTENSIONS
      end

      def url?(path)
        path.start_with?(*%w[http https])
      end

      # Attempt to process the tag as a page link tag.
      #
      # tag - The String tag contents (the stuff inside the double brackets).
      #
      # Returns the String HTML if the tag is a valid page link tag or nil
      # if it is not.
      def process_page_link_tag(parts)
        if parts.size == 1
          reference = parts[0].strip
        else
          name, reference = *parts.compact.map(&:strip)
        end

        class_list = 'gfm'
        additional_data = {
          'canonical-src': reference,
          link: true,
          gollum: true
        }

        if url?(reference)
          href = reference
        elsif wiki
          href = ::File.join(wiki_base_path, reference)
          class_list += " gfm-gollum-wiki-page"

          additional_data['reference-type'] = 'wiki_page'
          additional_data[:project] = context[:project].id if context[:project]
          additional_data[:group] = context[:group]&.id if context[:group]
        end

        if href
          sanitized_content_tag(:a, name || reference, href: href, class: class_list, data: additional_data)
        end
      end

      def wiki
        context[:wiki] || context[:project]&.wiki || context[:group]&.wiki
      end

      def wiki_base_path
        wiki&.wiki_base_path
      end

      def sanitized_content_tag(name, content, options = {})
        html = content_tag(name, content, options)
        node = Banzai::Filter::SanitizationFilter.new(html).call
        link_node = node&.children&.first

        link_node.add_class(options[:class])
        options[:data]&.each do |key, value|
          link_node.set_attribute("data-#{key}", value)
        end

        link_node
      end
    end
  end
end
