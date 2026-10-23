# typed: strict
# frozen_string_literal: true

require "cmd/shared_examples/args_parse"
require "dev-cmd/generate-analytics-api"

RSpec.describe Homebrew::DevCmd::GenerateAnalyticsApi do
  it_behaves_like "parseable arguments"

  it "generates release analytics without InfluxDB or GitHub queries" do
    allow_any_instance_of(Utils::Analytics::Influx).to receive(:setup_python).and_raise("Unexpected InfluxDB setup")
    allow(GitHub::API).to receive(:open_rest).and_raise("Unexpected GitHub query")
    allow(Utils::Analytics::Releases).to receive(:new).and_return(
      instance_double(Utils::Analytics::Releases, report: { "releases" => [{ "version" => "1.0.0" }] }),
    )
    mktmpdir.cd do
      described_class.new(["--releases"]).run

      expect(JSON.parse(Pathname("_data/analytics/releases/history.json").read))
        .to eq("releases" => [{ "version" => "1.0.0" }])
    end
  end

  [0, -1, 1001].each do |limit|
    it "rejects a download limit of #{limit}" do
      T.bind(self, RSpec::Core::ExampleGroup)
      expect { described_class.new(["--github-packages-limit=#{limit}"]).github_packages_limit }
        .to raise_error(UsageError, /between 1 and 1000/)
    end
  end

  it "rejects an all-formula download limit before starting network generation" do
    allow_any_instance_of(Utils::Analytics::Influx).to receive(:setup_python).and_raise("Unexpected network setup")

    expect { described_class.new(["--github-packages-limit=all"]).run }
      .to raise_error(UsageError, /between 1 and 1000/)
  end
end
