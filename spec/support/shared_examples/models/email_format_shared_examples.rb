# frozen_string_literal: true

# Specifications for behavior common to all objects with an email attribute.
# Takes a list of email-format attributes and requires:
# - subject { "the object with a attribute= setter"  }
#   Note: You have access to `email_value` which is the email address value
#         being currently tested).

RSpec.shared_examples 'an object with email-formatted attributes' do |*attributes|
  attributes.each do |attribute|
    describe "specifically its :#{attribute} attribute" do
      %w[
        info@example.com
        info+test@example.com
        o'reilly@example.com
        mailto:test@example.com
        test?=avalidemail@gmail.com
        validemail?=@gmail.com
        lol!'+=?><#$%^&*()@gmail.com
      ].each do |valid_email|
        context "with a value of '#{valid_email}'" do
          let(:email_value) { valid_email }

          it 'is valid' do
            subject.send("#{attribute}=", valid_email)

            expect(subject).to be_valid
          end
        end
      end

      %w[
        foobar
        test@test@example.com
        test=?invalidcharacter?=@example.com
        user+company=?example?=@example.com
        =?iso-8859-1?q?testencodedformat=40new.example.com=3e=20?=testencodedformat@example.com
        =?iso-8859-1?q?testencodedformat=40new.example.com?=testencodedformat@example.com
      ].each do |invalid_email|
        context "with a value of '#{invalid_email}'" do
          let(:email_value) { invalid_email }

          it 'is invalid' do
            subject.send("#{attribute}=", invalid_email)

            expect(subject).to be_invalid
          end
        end
      end
    end
  end
end

RSpec.shared_examples 'an object with RFC3696 compliant email-formatted attributes' do |*attributes|
  attributes.each do |attribute|
    describe "specifically its :#{attribute} attribute" do
      %w[
        info@example.com
        info+test@example.com
        o'reilly@example.com
      ].each do |valid_email|
        context "with a value of '#{valid_email}'" do
          let(:email_value) { valid_email }

          it 'is valid' do
            subject.send("#{attribute}=", valid_email)

            expect(subject).to be_valid
          end
        end
      end

      %w[
        foobar
        test@test@example.com
        test.test.@example.com
        .test.test@example.com
        mailto:test@example.com
        lol!'+=?><#$%^&*()@gmail.com
      ].each do |invalid_email|
        context "with a value of '#{invalid_email}'" do
          let(:email_value) { invalid_email }

          it 'is invalid' do
            subject.send("#{attribute}=", invalid_email)

            expect(subject).to be_invalid
          end
        end
      end
    end
  end
end
