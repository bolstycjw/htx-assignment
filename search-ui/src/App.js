import React from "react";
import {
  SearchProvider,
  SearchBox,
  Results,
  Paging
} from "@elastic/react-search-ui";
import { Layout } from "@elastic/react-search-ui-views";
import ElasticsearchAPIConnector from "@elastic/search-ui-elasticsearch-connector";

import "@elastic/react-search-ui-views/lib/styles/styles.css";

// Configure the Elasticsearch connector
const connector = new ElasticsearchAPIConnector({
  host: process.env.ELASTICSEARCH_URL || "http://localhost:9200",
  index: process.env.ELASTICSEARCH_INDEX || "cv-transcriptions",
});

// Simplified configuration
const config = {
  alwaysSearchOnInitialLoad: true,
  apiConnector: connector,
  searchQuery: {
    result_fields: {
      generated_text: { raw: {} },
      duration: { raw: {} },
      age: { raw: {} },
      gender: { raw: {} },
      accent: { raw: {} }
    },
    search_fields: {
      "generated_text": {},
      "accent": {},
      "age": {},
      "gender": {},
    },
  },
};

const App = () => (
  <SearchProvider config={config}>
    <Layout
      header={<SearchBox />}
      bodyContent={
        <Results
          titleField="generated_text"
          resultView={({ result }) => (
            <div className="result">
              <h3>{result.generated_text && result.generated_text.raw}</h3>
              {result.duration && result.duration.raw && (
                <div>
                  <strong>Duration:</strong> {result.duration.raw}s
                </div>
              )}
              {result.age && result.age.raw && (
                <div>
                  <strong>Age:</strong> {result.age.raw}
                </div>
              )}
              {result.gender && result.gender.raw && (
                <div>
                  <strong>Gender:</strong> {result.gender.raw}
                </div>
              )}
              {result.accent && result.accent.raw && (
                <div>
                  <strong>Accent:</strong> {result.accent.raw}
                </div>
              )}
            </div>
          )}
        />
      }
      bodyFooter={<Paging />}
    />
  </SearchProvider>
);

export default App; 