import React, {useState, useEffect} from 'react';
import {View, Text, StyleSheet} from 'react-native';
import ShareExtension from 'rn-extensions-share';

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
});

const Share = () => {
  const [data, setData] = useState();

  useEffect(() => {
    (async function () {
      const result = await ShareExtension.data();
      setData(result);
    })();
  }, []);

  return (
    <View style={styles.container}>
      <Text>{data ? JSON.stringify(data) : 'Data is not available'}</Text>
      {data?.length && <Text>{`length: ${data.length}`}</Text>}
    </View>
  );
};

export default Share;
