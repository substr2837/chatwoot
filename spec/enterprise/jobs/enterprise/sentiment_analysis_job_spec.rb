require 'rails_helper'

RSpec.describe Enterprise::SentimentAnalysisJob do
  context 'when account locale set to english language' do
    let(:account) { create(:account, locale: 'en') }
    let(:message) { build(:message, content_type: nil, account: account) }

    context 'when update the message sentiments' do
      let(:model_path) { 'sentiment-analysis.onnx' }
      let(:model) { double }

      before do
        allow(Informers::SentimentAnalysis).to receive(:new).with(model_path).and_return(model)
        allow(model).to receive(:predict).and_return({ label: 'positive', score: '0.6' })
      end

      it 'with incoming message' do
        with_modified_env SENTIMENT_FILE_PATH: 'sentiment-analysis.onnx' do
          message.update(message_type: :incoming)

          described_class.perform_now(message)

          expect(message.sentiment).not_to be_empty
        end
      end

      it 'update sentiment label for positive message' do
        with_modified_env SENTIMENT_FILE_PATH: 'sentiment-analysis.onnx' do
          message.update(message_type: :incoming, content: 'I like your product')

          described_class.perform_now(message)

          expect(message.sentiment).not_to be_empty
          expect(message.sentiment['label']).to eq('positive')
          expect(message.sentiment['value']).to eq(1)
        end
      end

      it 'update sentiment label for negative message' do
        with_modified_env SENTIMENT_FILE_PATH: 'sentiment-analysis.onnx' do
          message.update(message_type: :incoming, content: 'I did not like your product')
          allow(model).to receive(:predict).and_return({ label: 'negative', score: '0.6' })

          described_class.perform_now(message)

          expect(message.sentiment).not_to be_empty
          expect(message.sentiment['label']).to eq('negative')
          expect(message.sentiment['value']).to eq(-1)
        end
      end
    end

    context 'when does not update the message sentiments' do
      it 'with outgoing message' do
        message.update(message_type: :outgoing)

        described_class.perform_now(message)

        expect(message.sentiment).to be_empty
      end

      it 'with private message' do
        message.update(private: true)

        described_class.perform_now(message)

        expect(message.sentiment).to be_empty
      end
    end
  end

  context 'when account locale is not set to english language' do
    let(:account) { create(:account, locale: 'es') }
    let(:message) { build(:message, content_type: nil, account: account) }

    it 'does not update the message sentiments' do
      described_class.perform_now(message)

      expect(message.sentiment).to be_empty
    end
  end
end
