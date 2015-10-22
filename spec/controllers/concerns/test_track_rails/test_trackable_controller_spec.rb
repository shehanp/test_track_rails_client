require 'rails_helper'

RSpec.describe TestTrackRails::TestTrackableController do
  mixin = described_class

  controller(ApplicationController) do
    include mixin

    def index
      render json: { split_registry: test_track_visitor.split_registry, assignment_registry: test_track_visitor.assignment_registry }
    end
  end

  def response_json
    @response_json ||= JSON.parse(response.body)
  end

  let(:existing_visitor_id) { SecureRandom.uuid }
  let(:split_registry) { { 'time' => { 'beer_thirty' => 100 } } }
  let(:assignment_registry) { { 'time' => 'beer_thirty' } }

  before do
    allow(TestTrackRails::SplitRegistry).to receive(:to_hash).and_return(split_registry)
    allow(TestTrackRails::AssignmentRegistry).to receive(:fake_instance_attributes).and_return(assignment_registry)
  end


  it "responds with the action's usual http status" do
    get :index
    expect(response).to have_http_status(:ok)
  end

  it "returns the split registry" do
    get :index
    expect(response_json['split_registry']).to eq(split_registry)
  end

  it "returns an empty assignment registry for a generated visitor" do
    get :index
    expect(response_json['assignment_registry']).to eq({})
    expect(TestTrackRails::AssignmentRegistry).not_to have_received(:fake_instance_attributes)
  end

  it "returns a server-provided assignment registry for an existing visitor" do
    request.cookies['tt_visitor_id'] = existing_visitor_id
    get :index
    expect(response_json['assignment_registry']).to eq(assignment_registry)
  end

  it "sets a UUID tt_visitor_id cookie if unset" do
    expect(request.cookies['tt_visitor_id']).to eq nil
    get :index
    expect(response.cookies['tt_visitor_id']).to match(/[0-9a-f\-]{36}/)
  end

  it "preserves tt_visitor_id cookie if set" do
    request.cookies['tt_visitor_id'] = existing_visitor_id
    get :index
    expect(response.cookies['tt_visitor_id']).to eq existing_visitor_id
  end
end
