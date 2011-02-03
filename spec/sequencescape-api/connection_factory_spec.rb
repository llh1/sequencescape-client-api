require 'spec_helper'

describe Sequencescape::Api::ConnectionFactory do
  describe '.create' do
    it 'errors if no :cookie is set' do
      lambda { described_class.create(:url => 'foo') }.should raise_error(Sequencescape::Api::Error)
    end

    it 'errors if no :url is set' do
      lambda { described_class.create(:cookie => 'foo') }.should raise_error(Sequencescape::Api::Error)
    end

    it 'uses the default_url if it has been set' do
      described_class.default_url = 'default url'
      described_class.create(:cookie => 'foo').send(:url).should == 'default url'
    end

    it 'the specified URL overrides default_url' do
      described_class.default_url = 'default url'
      described_class.create(:cookie => 'foo', :url => 'i want this one').send(:url).should == 'i want this one'
    end
  end

  describe 'connection instance behaviour' do
    context 'normal behaviour' do
      subject do 
        described_class.create(:url => 'http://localhost:3000/', :cookie => 'testing')
      end

      describe '#url_for_uuid' do
        it 'combines the URL specified with the UUID' do
          subject.url_for_uuid('UUID').should == 'http://localhost:3000/UUID'
        end
      end

      describe '#root' do
        it 'reads the JSON from the root URL' do
          subject.should_receive(:read).with('http://localhost:3000/').and_yield(:json_from_root_url)
          subject.root { |json| json.should == :json_from_root_url }
        end
      end
    end

    shared_examples_for 'it creates, reads and updates' do
      describe '#read' do
        it 'does an HTTP GET for the URL specified' do
          stub_request(:get, 'http://localhost:3000/').with(
            :headers => {
              'Cookie' => 'WTSISignOn=testing',
              'Accept' => 'application/json'
            }.merge(headers)
          ).to_return(
            :status  => 200,
            :headers => { 'Content-Type' => 'application/json' },
            :body    => %Q{{ "a" : 1 }}
          )

          expected = double('expected')
          expected.should_receive(:yielded).with({ 'a' => 1 })

          subject.read('http://localhost:3000/', &expected.method(:yielded))
        end
      end

      describe '#create' do
        it 'does an HTTP POST with the parameters as JSON to the URL specified' do
          stub_request(:post, 'http://localhost:3000/create').with(
            :headers => {
              'Cookie' => 'WTSISignOn=testing',
              'Accept' => 'application/json'
            }.merge(headers),
            :body => %Q{JSON!}
          ).to_return(
            :status  => 201,
            :headers => { 'Content-Type' => 'application/json' },
            :body    => %Q{{ "b" : 2 }}
          )

          expected = double('expected')
          expected.should_receive(:yielded).with({ 'b' => 2 })

          body = double('body')
          body.should_receive(:to_json).and_return('JSON!')

          subject.create('http://localhost:3000/create', body, &expected.method(:yielded))
        end
      end

      describe '#update' do
        it 'does an HTTP PUT with the parameters as JSON to the URL specified' do
          stub_request(:put, 'http://localhost:3000/update').with(
            :headers => {
              'Cookie' => 'WTSISignOn=testing',
              'Accept' => 'application/json'
            }.merge(headers),
            :body => %Q{JSON!}
          ).to_return(
            :status  => 200,
            :headers => { 'Content-Type' => 'application/json' },
            :body    => %Q{{ "b" : 2 }}
          )

          expected = double('expected')
          expected.should_receive(:yielded).with({ 'b' => 2 })

          body = double('body')
          body.should_receive(:to_json).and_return('JSON!')

          subject.update('http://localhost:3000/update', body, &expected.method(:yielded))
        end
      end
    end

    context 'HTTP interaction' do
      context 'authorised behaviour' do
        subject do 
          described_class.create(:url => 'http://localhost:3000/', :cookie => 'testing', :authorisation => 'knock-knock')
        end

        let(:headers) do
          { 'X-Sequencescape-Client-ID' => 'knock-knock' }
        end

        it_should_behave_like 'it creates, reads and updates'
      end

      context 'unauthorised behaviour' do
        subject do 
          described_class.create(:url => 'http://localhost:3000/', :cookie => 'testing')
        end

        let(:headers) do
          { }
        end

        it_should_behave_like 'it creates, reads and updates'
      end
    end
  end
end
