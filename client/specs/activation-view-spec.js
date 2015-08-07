/* global describe, it, expect */
/* global jasmine, beforeEach, afterEach */

define(['scripts/activation-view.jsx'], function(ActivationView) {

  function toArray(elements) {
    var content = [];
    for (var i = 0, imax = elements.length; i < imax; ++i) {
      content.push(elements[i].innerHTML);
    }
    return content;
  }

  function parseTable(element) {
    var tableContent = [];

    var table = element.querySelector('table');
    var rows = table.getElementsByTagName('tr');
    if (rows.length > 0) {
      tableContent.push(toArray(rows[0].getElementsByTagName('th')));
      for (var i = 1, imax = rows.length; i < imax; ++i) {
        tableContent.push(toArray(rows[i].getElementsByTagName('td')));
      }
    }
    return tableContent;
  }

  describe('activation-view.jsx', function() {
    var testDiv;

    beforeEach(function() {
      testDiv = document.createElement('div');
      document.body.appendChild(testDiv);
    });
    afterEach(function() {
      document.body.removeChild(testDiv);
    });

    it('Check table content', function() {
      var testData = [
        {token: 'tok1', chatName: 'Chat #11', code: 123456},
        {token: 'tok2', chatName: 'Chat #22', code: 456789},
        {token: 'tok3', chatName: 'Chat #33', code: 344393}
      ];

      var view = ActivationView.create(testDiv);
      view.setState({data: testData});

      expect(parseTable(testDiv)).toEqual([
        ['Token', 'Chat name', 'Activation code'],
        ['tok1', 'Chat #11', '123456'],
        ['tok2', 'Chat #22', '456789'],
        ['tok3', 'Chat #33', '344393']
      ]);
    });

    it('Check submit', function() {
      var onSubmit = jasmine.createSpy('onSubmit');
      ActivationView.create(testDiv, onSubmit);

      var form = testDiv.querySelector('form');
      form.chatName.value = ' test chat name ';
      testDiv.querySelector('button[type=submit]').click();
      expect(onSubmit).toHaveBeenCalledWith('test chat name');
    });
  });
});
