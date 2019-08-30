// @flow

export type CardParameters = {
  number: string,
  cvv: string,
  expiration_date: string,
  cardholderName: string,
  givenName: string;
  surname: string;
  firstName: string,
  lastName: string,
  company: string,
  countryName: string,
  countryCodeAlpha2: string,
  countryCodeAlpha3: string,
  countryCodeNumeric: string,
  locality: string,
  postalCode: string,
  region: string,
  streetAddress: string,
  extendedAddress: string,
};

export type IOSCardParameters = {
  number: string,
  cvv: string,
  expiration_date: string,
  cardholderName: string,
  givenName: string;
  surname: string;
  billingAddress: {
    postalCode: string,
    streetAddress: string,
    extendedAddress: string,
    locality: string,
    region: string,
    countryName: string,
    countryCodeAlpha2: string,
    countryCodeAlpha3: string,
    countryCodeNumeric: string,
    firstName: string,
    lastName: string,
    company: string,
  },
};

export type AndroidCardParameters = CardParameters;
