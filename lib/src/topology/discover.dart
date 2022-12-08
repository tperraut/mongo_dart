import 'package:mongo_dart/mongo_dart.dart';

import 'abstract/topology.dart';
import 'standalone.dart';

/// This is a class used uniquely to discover which is the
/// topology of our connection.
/// It tries to connect on each seed server until it is able to
/// discover the topology.
/// Once that it is done it can build the correct object.
/// Here the connection is made only on one server.
/// The correct topology object will have to complete all the connections.
class Discover extends Topology {
  Discover(super.hostsSeedList, super.mongoClientOptions) : super.protected();

  Topology getEffectiveTopology() {
    Topology topology;
    if (servers.first.isStandalone) {
      topology = Standalone(hostsSeedList, mongoClientOptions);
    } else if (servers.first.isReplicaSet) {
      // Todo
      topology = Standalone(hostsSeedList, mongoClientOptions);
    } else if (servers.first.isReplicaSet) {
      // Todo
      topology = Standalone(hostsSeedList, mongoClientOptions);
    } else {
      throw MongoDartError('Unknown topology type');
    }
    topology.servers.add(servers.first);

    return topology;
  }
}