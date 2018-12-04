#!/usr/bin/env rspec

# Copyright (c) [2018] SUSE LLC
#
# All Rights Reserved.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License as published
# by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, contact SUSE LLC.
#
# To contact SUSE LLC about this file by physical or electronic mail, you may
# find current contact information at www.suse.com.

require_relative "../../spec_helper"
require "y2configuration_management/salt/formula_sequence"
require "y2configuration_management/salt/formula"
require "cwm/rspec"

describe Y2ConfigurationManagement::Salt::FormulaSequence do
  let(:formulas_root) { FIXTURES_PATH.join("formulas-ng") }
  let(:form) { formulas_root.join("form.yml") }
  let(:formulas) { Y2ConfigurationManagement::Salt::Formula.all(formulas_root.to_s) }
  let(:selector) { instance_double(Y2ConfigurationManagement::Salt::FormulaSelection) }
  let(:formula_config_sequence) do
    instance_double(Y2ConfigurationManagement::Salt::FormulaConfiguration)
  end
  subject(:sequence) { described_class.new(formulas) }

  describe "#run" do
    context "if the user aborts during the process" do
      before do
        allow(sequence).to receive(:choose_formulas).and_return(:abort)
      end

      it "returns :abort" do
        expect(sequence.run).to eql(:abort)
      end

      it "does not apply any salt state" do
        expect(sequence).to_not receive(:apply_formulas)
        sequence.run
      end
    end

    context "if the user selects and configures all the formulas" do
      before do
        allow(sequence).to receive(:choose_formulas).and_return(:next)
        allow(sequence).to receive(:configure_formulas).and_return(:next)
      end

      it "applies the salt states" do
        expect(sequence).to receive(:apply_formulas)
        sequence.run
      end
    end
  end

  describe "#choose_formulas" do
    before do
      allow(Yast::Report).to receive(:Error)
      allow(Y2ConfigurationManagement::Salt::FormulaSelection)
        .to receive(:new).with(formulas).and_return(selector)
    end

    context "when there are not formulas available in the system" do
      let(:formulas) { [] }
      it "reports an error" do
        expect(Yast::Report).to receive(:Error).with(/There are no formulas available/)

        sequence.choose_formulas
      end

      it "returns :abort" do
        expect(sequence.choose_formulas).to eql(:abort)
      end
    end

    context "when there are some formulas available in the system" do
      it "runs the formula selection dialog" do
        expect(selector).to receive(:run)

        sequence.choose_formulas
      end
    end
  end

  describe "#configure_formulas" do
    before do
      allow(Y2ConfigurationManagement::Salt::FormulaConfiguration)
        .to receive(:new).with(formulas).and_return(formula_config_sequence)
    end

    it "runs the formulas configuration sequence" do
      expect(formula_config_sequence).to receive(:run)

      sequence.configure_formulas
    end
  end

  describe "#apply_formulas" do
    before do
      formulas.each { |f| allow(f).to receive(:enabled?).and_return(true) }
    end

    context "when no formula was selected to be applied" do
      let(:formulas) { [] }

      it "returns :next without notifying" do
        expect(Yast::Popup).to_not receive(:Feedback)
        expect(sequence.apply_formulas).to eql(:next)
      end
    end

    it "popups a feedback message" do
      expect(Yast::Popup).to receive(:Feedback)
      sequence.apply_formulas
    end

    it "returns :next" do
      allow(Yast::Popup).to receive(:Feedback)
      expect(sequence.apply_formulas).to eql(:next)
    end
  end
end
