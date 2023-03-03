# Kubik Previewable

Add previews for your resource pages to your ActiveAdmin dashboard alongside your other admin actions.

## Installation

```ruby
gem 'kubik_metatagable'
```

And then execute:

```bash
bundle install
```

## Usage

Include the module in your model and add the configuration for your preview layout, template, and local assigns. By default, we'll fetch a `@page = Page.find(id)` for you (whatever your model name is), but anything else is up to you to pass in as a string or proc.

```ruby
class Page < ActiveRecord
  include ::Kubik::Previewable
  kubik_previewable
end
```

Our pages generally have a `template` field that defines a template to use. This might be implemented like this:

```ruby
class Page < ActiveRecord
  LAYOUTS = {
    home: 'Home',
    standard: 'Standard'
  }.freeze

  include ::Kubik::Previewable
  kubik_previewable(
    template: ->(page) { "pages/#{page.template}" } # app/views/pages/#{template_id}
    instance_variables: ->(page) { { page: page, pages_navigation: PagesNavigation.find(page) } },
  )
end
```

Include the `Kubik::PreviewableAdminAction` in the specific `ActiveAdmin.resource` block

```ruby
ActiveAdmin.register Page do
  include Kubik::PreviewableAdminAction
  ...
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/kubik_previewable. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/kubik_previewable/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the KubikPreviewable project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/kubik_previewable/blob/master/CODE_OF_CONDUCT.md).
