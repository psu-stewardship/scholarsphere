# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Work, type: :model do
  it_behaves_like 'a resource with permissions' do
    let(:factory_name) { :work }
  end

  it_behaves_like 'a resource with a generated uuid' do
    let(:resource) { build(:work) }
  end

  it_behaves_like 'a resource with a deposited at timestamp'

  it_behaves_like 'a resource that can provide all DOIs in', [:doi]

  describe 'table' do
    it { is_expected.to have_db_column(:work_type).of_type(:string) }
    it { is_expected.to have_db_column(:depositor_id) }
    it { is_expected.to have_db_column(:proxy_id) }
    it { is_expected.to have_db_column(:doi).of_type(:string) }
    it { is_expected.to have_db_column(:embargoed_until).of_type(:datetime) }
    it { is_expected.to have_db_column(:deposit_agreed_at).of_type(:datetime) }
    it { is_expected.to have_db_column(:deposit_agreement_version) }

    it { is_expected.to have_db_index(:depositor_id) }
    it { is_expected.to have_db_index(:proxy_id) }
  end

  describe 'factories' do
    it { is_expected.to have_valid_factory(:work) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:depositor).class_name('Actor').with_foreign_key(:depositor_id).inverse_of(:deposited_works) }
    it { is_expected.to belong_to(:proxy_depositor).class_name('Actor').with_foreign_key(:proxy_id).inverse_of(:proxy_deposited_works).optional }
    it { is_expected.to have_many(:access_controls) }
    it { is_expected.to have_many(:versions).class_name('WorkVersion').inverse_of('work') }
    it { is_expected.to have_many(:legacy_identifiers) }
    it { is_expected.to have_many(:collection_work_memberships) }
    it { is_expected.to have_many(:collections).through(:collection_work_memberships) }

    it { is_expected.to accept_nested_attributes_for(:versions) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:work_type) }
    it { is_expected.to validate_presence_of(:versions) }
  end

  describe '::Types' do
    subject(:types) { described_class::Types }

    describe '.all' do
      subject(:all) { types.all }

      specify do
        expect(all).to contain_exactly(
          'article',
          'audio',
          'book',
          'capstone_project',
          'collection',
          'conference_proceeding',
          'dataset',
          'dissertation',
          'image',
          'journal',
          'map_or_cartographic_material',
          'masters_culminating_experience',
          'masters_thesis',
          'other',
          'part_of_book',
          'poster',
          'presentation',
          'project',
          'report',
          'research_paper',
          'software_or_program_code',
          'thesis',
          'unspecified',
          'video'
        )
      end
    end

    describe '.default' do
      subject { types.default }

      it { is_expected.to eq('dataset') }
    end

    describe '.thesis' do
      subject { types.thesis }

      it { is_expected.to eq('thesis') }
    end

    describe '.unspecified' do
      subject { types.unspecified }

      it { is_expected.to eq('unspecified') }
    end

    describe '.options_for_select_box' do
      subject(:options) { types.options_for_select_box }

      it { is_expected.to include(['Dataset', 'dataset'], ['Part Of Book', 'part_of_book']) }
      it { is_expected.not_to include(['Unspecified', 'unspecified']) }
    end

    describe '.display' do
      it 'returns a human-readable version of the type' do
        expect(types.display(types.default)).to eq('Dataset')
      end
    end
  end

  describe '::DepositAgreement::CURRENT_VERSION' do
    subject { described_class::DepositAgreement::CURRENT_VERSION }

    it { is_expected.to eq('2.0') }
  end

  describe '#update_deposit_agreement' do
    context 'when the deposit agreement version is nil' do
      let(:work) { build(:work) }

      it 'updates the agreement version' do
        expect {
          work.update_deposit_agreement
        }.to change(work, :deposit_agreement_version).from(nil).to(described_class::DepositAgreement::CURRENT_VERSION)
      end
    end

    context 'when the work has the current deposit agreement version' do
      let(:work) { build(:work, deposit_agreement_version: described_class::DepositAgreement::CURRENT_VERSION) }

      it 'does NOT update the agreement version timestamp' do
        expect {
          work.update_deposit_agreement
        }.not_to(change(work, :deposit_agreed_at))
      end
    end
  end

  describe '#work_type' do
    specify do
      expect(described_class.new).to define_enum_for(:work_type)
        .with_values(
          article: 'article',
          audio: 'audio',
          book: 'book',
          capstone_project: 'capstone_project',
          collection: 'collection',
          conference_proceeding: 'conference_proceeding',
          dataset: 'dataset',
          dissertation: 'dissertation',
          image: 'image',
          journal: 'journal',
          map_or_cartographic_material: 'map_or_cartographic_material',
          masters_culminating_experience: 'masters_culminating_experience',
          masters_thesis: 'masters_thesis',
          other: 'other',
          part_of_book: 'part_of_book',
          poster: 'poster',
          presentation: 'presentation',
          project: 'project',
          report: 'report',
          research_paper: 'research_paper',
          software_or_program_code: 'software_or_program_code',
          thesis: 'thesis',
          unspecified: 'unspecified',
          video: 'video'
        )
        .backed_by_column_of_type(:string)
    end
  end

  describe '.build_with_empty_version' do
    it 'builds a Work with one empty version' do
      work = described_class.build_with_empty_version
      expect(work.versions.length).to eq 1
    end

    it 'sets the version number to 1' do
      work = described_class.build_with_empty_version
      expect(work.versions.first.version_number).to eq 1
    end

    it 'passes through any arguments provided' do
      work_type = described_class::Types.all.first
      work = described_class.build_with_empty_version(work_type: work_type)
      expect(work.versions).to be_present
      expect(work.work_type).to eq work_type
    end

    it 'will not overwrite a provided version' do
      versions = [WorkVersion.new]
      new_work = described_class.build_with_empty_version(versions: versions)
      expect(new_work.versions).to match_array(versions)
    end
  end

  describe 'initialize' do
    it 'does not initialize a work version too' do
      expect(described_class.new.versions).to be_empty
    end

    it 'accepts initial work versions' do
      versions = [WorkVersion.new]
      new_work = described_class.new(versions: versions)
      expect(new_work.versions).to match_array(versions)
    end
  end

  describe 'version accessors' do
    let(:draft) { build :work_version, :draft, title: 'Draft', work: nil, created_at: 1.day.ago, version_number: 3 }
    let(:v2) { build :work_version, :published, title: 'Published v2', work: nil, created_at: 2.days.ago, version_number: 2 }
    let(:v1) { build :work_version, :published, title: 'Published v1', work: nil, created_at: 3.days.ago, version_number: 1 }
    let(:withdrawn) { build :work_version, :withdrawn, work: nil, created_at: 3.days.ago, version_number: 1 }

    before { work.reload }

    context 'with draft, published, and withdrawn versions' do
      subject(:work) { create :work, versions: [draft, v2, withdrawn] }

      it { is_expected.not_to be_withdrawn }

      its(:latest_version) { is_expected.to eq(draft) }
      its(:latest_published_version) { is_expected.to eq(v2) }
      its(:draft_version) { is_expected.to eq(draft) }
      its(:withdrawn_version) { is_expected.to eq(withdrawn) }
      its(:representative_version) { is_expected.to eq(v2) }
    end

    context 'with draft and published versions' do
      subject(:work) { create :work, versions: [draft, v2, v1] }

      it { is_expected.not_to be_withdrawn }

      its(:latest_version) { is_expected.to eq(draft) }
      its(:latest_published_version) { is_expected.to eq(v2) }
      its(:draft_version) { is_expected.to eq(draft) }
      its(:withdrawn_version) { is_expected.to be_nil }
      its(:representative_version) { is_expected.to eq(v2) }
    end

    context 'with draft and withdrawn versions' do
      subject(:work) { create :work, versions: [draft, withdrawn] }

      it { is_expected.to be_withdrawn }

      its(:latest_version) { is_expected.to eq(draft) }
      its(:latest_published_version) { is_expected.to be_nil }
      its(:draft_version) { is_expected.to eq(draft) }
      its(:withdrawn_version) { is_expected.to eq(withdrawn) }
      its(:representative_version) { is_expected.to eq(withdrawn) }
    end

    context 'with published and withdrawn versions' do
      subject(:work) { create :work, versions: [v2, withdrawn] }

      it { is_expected.not_to be_withdrawn }

      its(:latest_version) { is_expected.to eq(v2) }
      its(:latest_published_version) { is_expected.to eq(v2) }
      its(:draft_version) { is_expected.to be_nil }
      its(:withdrawn_version) { is_expected.to eq(withdrawn) }
      its(:representative_version) { is_expected.to eq(v2) }
    end

    context 'with only published versions' do
      subject(:work) { create :work, versions: [v2, v1] }

      it { is_expected.not_to be_withdrawn }

      its(:latest_version) { is_expected.to eq(v2) }
      its(:latest_published_version) { is_expected.to eq(v2) }
      its(:draft_version) { is_expected.to be_nil }
      its(:withdrawn_version) { is_expected.to be_nil }
      its(:representative_version) { is_expected.to eq(v2) }
    end

    context 'with only a draft version' do
      subject(:work) { create :work, versions: [draft] }

      it { is_expected.not_to be_withdrawn }

      its(:latest_version) { is_expected.to eq(draft) }
      its(:latest_published_version) { is_expected.to be_nil }
      its(:draft_version) { is_expected.to eq(draft) }
      its(:withdrawn_version) { is_expected.to be_nil }
      its(:representative_version) { is_expected.to eq(draft) }
    end

    context 'with only a withdrawn version' do
      subject(:work) { create :work, versions: [withdrawn] }

      it { is_expected.to be_withdrawn }

      its(:latest_version) { is_expected.to eq(withdrawn) }
      its(:latest_published_version) { is_expected.to be_nil }
      its(:draft_version) { is_expected.to be_nil }
      its(:withdrawn_version) { is_expected.to eq(withdrawn) }
      its(:representative_version) { is_expected.to eq(withdrawn) }
    end
  end

  describe '#resource_with_doi' do
    let(:work) { described_class.new }

    it 'returns `self`' do
      expect(work.resource_with_doi).to eq work
    end
  end

  describe '#to_solr' do
    context 'when the work only has a draft version' do
      subject { build(:work).to_solr }

      let(:keys) do
        %w(
          all_dois_ssim
          created_at_dtsi
          deposit_agreed_at_dtsi
          deposit_agreement_version_tesim
          deposited_at_dtsi
          depositor_id_isi
          discover_groups_ssim
          discover_users_ssim
          display_work_type_ssi
          doi_tesim
          edit_groups_ssim
          edit_users_ssim
          embargoed_until_dtsi
          id
          model_ssi
          proxy_id_isi
          read_groups_ssim
          read_users_ssim
          updated_at_dtsi
          uuid_ssi
          visibility_ssi
          work_type_ss
        )
      end

      its(:keys) { is_expected.to contain_exactly(*keys) }
    end

    context 'when the work has a published version' do
      subject { create(:work, has_draft: false).to_solr }

      let(:keys) do
        %w(
          aasm_state_tesim
          all_dois_ssim
          based_near_tesim
          contributor_tesim
          created_at_dtsi
          creators_sim
          creators_tesim
          deposit_agreed_at_dtsi
          deposit_agreement_version_tesim
          deposited_at_dtsi
          depositor_id_isi
          description_tesim
          discover_groups_ssim
          discover_users_ssim
          display_work_type_ssi
          doi_tesim
          edit_groups_ssim
          edit_users_ssim
          embargoed_until_dtsi
          file_resource_ids_ssim
          file_version_titles_ssim
          id
          identifier_tesim
          keyword_sim
          keyword_tesim
          language_tesim
          model_ssi
          proxy_id_isi
          published_date_dtrsi
          published_date_tesim
          publisher_statement_tesim
          publisher_tesim
          read_groups_ssim
          read_users_ssim
          related_url_tesim
          rights_tesim
          source_tesim
          subject_sim
          subject_tesim
          subtitle_tesim
          title_ssort
          title_tesim
          updated_at_dtsi
          uuid_ssi
          version_name_tesim
          version_number_isi
          visibility_ssi
          work_id_isi
          work_type_ss
        )
      end

      its(:keys) { is_expected.to contain_exactly(*keys) }
    end
  end

  describe '::reindex_all' do
    before do
      create_list(:work, 2)
      allow(IndexingService).to receive(:commit)
      allow(WorkIndexer).to receive(:call)
    end

    context 'without any arguments' do
      it 'reindexes all the works and their versions into solr synchronously' do
        allow(SolrIndexingJob).to receive(:perform_later)
        described_class.reindex_all
        expect(WorkIndexer).to have_received(:call).twice
        expect(IndexingService).to have_received(:commit).once
        expect(SolrIndexingJob).not_to have_received(:perform_later)
      end
    end

    context 'when given a relation' do
      let!(:special_work) { create(:work) }

      let(:only_special_works) { described_class.where(depositor: special_work.depositor) }

      it 'only reindexes works within that relation' do
        allow(SolrIndexingJob).to receive(:perform_later)
        described_class.reindex_all(relation: only_special_works)
        expect(WorkIndexer).to have_received(:call).once
        expect(WorkIndexer).to have_received(:call).with(special_work, anything)
        expect(SolrIndexingJob).not_to have_received(:perform_later)
      end
    end

    context 'with async: true' do
      it 'reindexes all the works and their versions into solr asynchronously' do
        allow(SolrIndexingJob).to receive(:perform_later)
        described_class.reindex_all(async: true)
        expect(WorkIndexer).not_to have_received(:call)
        expect(IndexingService).not_to have_received(:commit)
        expect(SolrIndexingJob).to have_received(:perform_later).once.with(kind_of(described_class), commit: false)
        expect(SolrIndexingJob).to have_received(:perform_later).once.with(kind_of(described_class), commit: true)
      end
    end
  end

  describe 'embargoed?' do
    context 'with an unembargoed public work' do
      subject { build(:work, has_draft: false) }

      it { is_expected.not_to be_embargoed }
    end

    context 'with an embargoed public work' do
      subject { build(:work, has_draft: false, embargoed_until: (Time.zone.now + 6.days)) }

      it { is_expected.to be_embargoed }
    end

    context 'with an previously embargoed public work' do
      subject { build(:work, has_draft: false, embargoed_until: (Time.zone.now - 6.months)) }

      it { is_expected.not_to be_embargoed }
    end
  end

  describe '#count_view!' do
    context 'when the work has a published version' do
      let(:work) { build(:work) }
      let(:version) { instance_spy('version') }

      before { allow(work).to receive(:latest_published_version).and_return(version) }

      it 'calls the method on the published version' do
        work.count_view!
        expect(version).to have_received(:count_view!)
      end
    end

    context 'when the work does NOT have a published version' do
      subject { work.count_view! }

      let(:work) { build(:work) }

      it { is_expected.to be_nil }
    end
  end

  describe '#stats' do
    subject(:work) { create :work, versions_count: 3, has_draft: true }

    before { allow(AggregateViewStatistics).to receive(:call).and_return(:returned_stats) }

    it 'Passes all published works to AggregateViewStatistics' do
      expect(work.stats).to eq :returned_stats
      expect(AggregateViewStatistics).to have_received(:call).with(models: work.versions.published)
    end
  end
end
