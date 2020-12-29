require 'rails_helper'

module BatchProcessingThread
  describe Client do
    let(:client) { Client.new(batch_size: 50) {} }
    let(:queue) { client.instance_variable_get :@queue }

    describe '#initialize' do
      it 'errors if no batch_size is supplied' do
        expect { Client.new {} }.to raise_error(ArgumentError)
      end

      it 'errors if no block is supplied' do
        expect { Client.new(batch_size: 50) }.to raise_error(ArgumentError)
      end

      it 'does not error if a batch_size and a block are supplied' do
        expect do
          Client.new(batch_size: 50) {}
        end.to_not raise_error
      end
    end

    describe '#flush' do
      it 'waits for the queue to finish on a flush' do
        client.enqueue :task_1
        client.enqueue :task_2
        client.flush

        expect(queue.length).to eq(0)
      end

      it 'completes when the process forks' do
        client.enqueue :task_1

        # the fork messes up with the db connection
        ActiveRecord::Base.connection.disconnect!

        Process.fork do
          client.enqueue :task_2
          client.flush
          expect(queue.length).to eq(0)
        end

        Process.wait

        ActiveRecord::Base.establish_connection
      end
    end
  end

  describe Worker do
    describe '#run' do
      let(:processor) { spy }

      it 'calls the processor with an array of tasks' do
        queue = Queue.new
        queue << :task_1
        queue << :task_2
        worker = Worker.new(queue, 50) do |batch|
          processor.process batch.dup
        end
        worker.run

        expect(queue).to be_empty
        expect(processor).to have_received(:process).with([:task_1, :task_2])
      end
    end

    describe '#is_requesting?' do
      it "returns false if there isn't a current batch" do
        queue = Queue.new
        worker = Worker.new(queue, 50) {}

        expect(worker.is_requesting?).to eq(false)
      end

      it 'returns true if there is a current batch' do
        queue = Queue.new
        queue << [:task_1]
        worker = worker = Worker.new(queue, 50) { sleep 0.1 }

        Thread.new do
          worker.run
          expect(worker.is_requesting?).to eq(false)
        end

        sleep 0.05
        expect(worker.is_requesting?).to eq(true)
      end
    end
  end
end
